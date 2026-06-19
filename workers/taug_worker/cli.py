from __future__ import annotations

import argparse
import json
import sys

from .config import WorkerConfig
from .http_client import HttpClient
from .jobs.fetch_sec_filing_documents import run_fetch_sec_filing_documents
from .jobs.sync_sec_submissions import run_sync_sec_submissions
from .sec_client import SecClient
from .supabase_rest import SupabaseRestClient


def main() -> int:
  parser = argparse.ArgumentParser(prog="taug-worker")
  subparsers = parser.add_subparsers(dest="command", required=True)

  sync_parser = subparsers.add_parser("sync-sec-submissions")
  sync_parser.add_argument(
    "--ciks",
    help="Comma-separated CIK list. Defaults to SEC_TARGET_CIKS.",
  )
  sync_parser.add_argument(
    "--max-companies",
    type=int,
    default=0,
    help="Optional cap after parsing the input list.",
  )
  sync_parser.add_argument(
    "--max-filings-per-company",
    type=int,
    default=25,
    help="Maximum number of recent filings to normalize per company in one run.",
  )
  document_parser = subparsers.add_parser("fetch-sec-filing-documents")
  document_parser.add_argument(
    "--limit",
    type=int,
    default=10,
    help="Maximum number of filing documents to fetch in one run.",
  )

  args = parser.parse_args()
  config = WorkerConfig.from_env()

  if args.command == "sync-sec-submissions":
    ciks: tuple[str, ...] = _resolve_ciks(args.ciks, config)
    if args.max_companies > 0:
      ciks = ciks[: args.max_companies]

    http_client = HttpClient()
    sec_client = SecClient(http_client=http_client, user_agent=config.sec_user_agent)
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )

    summary = run_sync_sec_submissions(
      ciks=ciks,
      sec_client=sec_client,
      supabase_client=supabase_client,
      max_filings_per_company=args.max_filings_per_company,
    )
    print(
      json.dumps(
        {
          "fetch_run_id": summary.fetch_run_id,
          "processed_ciks": summary.processed_ciks,
          "succeeded_ciks": summary.succeeded_ciks,
          "failed_ciks": summary.failed_ciks,
          "created_raw_records": summary.created_raw_records,
          "replayed_raw_records": summary.replayed_raw_records,
          "created_filings": summary.created_filings,
          "replayed_filings": summary.replayed_filings,
          "created_filing_versions": summary.created_filing_versions,
          "replayed_filing_versions": summary.replayed_filing_versions,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "fetch-sec-filing-documents":
    http_client = HttpClient()
    sec_client = SecClient(http_client=http_client, user_agent=config.sec_user_agent)
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_fetch_sec_filing_documents(
      sec_client=sec_client,
      supabase_client=supabase_client,
      bucket=config.raw_documents_bucket,
      limit=args.limit,
    )
    print(
      json.dumps(
        {
          "fetch_run_id": summary.fetch_run_id,
          "attempted_documents": summary.attempted_documents,
          "stored_documents": summary.stored_documents,
          "failed_documents": summary.failed_documents,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  raise ValueError(f"Unsupported command: {args.command}")


def _resolve_ciks(cli_value: str | None, config: WorkerConfig) -> tuple[str, ...]:
  if cli_value and cli_value.strip():
    return tuple(item.strip() for item in cli_value.split(",") if item.strip())
  if config.sec_target_ciks:
    return config.sec_target_ciks
  raise ValueError("No target CIKs provided. Use --ciks or SEC_TARGET_CIKS.")


if __name__ == "__main__":
  sys.exit(main())
