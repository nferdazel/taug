from __future__ import annotations

import argparse
import json
import sys

from .config import WorkerConfig
from .http_client import HttpClient
from .jobs.parse_sec_companyfacts import run_parse_sec_companyfacts
from .jobs.sync_sec_companyfacts import run_sync_sec_companyfacts
from .jobs.fetch_sec_filing_documents import run_fetch_sec_filing_documents
from .jobs.compute_company_metrics import run_compute_company_metrics
from .jobs.compute_data_quality import run_compute_data_quality
from .jobs.execute_screener import run_execute_screener
from .jobs.sync_bps_series import run_sync_bps_series
from .jobs.sync_fred_series import run_sync_fred_series
from .jobs.sync_price_snapshots import run_sync_price_snapshots
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
  companyfacts_parser = subparsers.add_parser("sync-sec-companyfacts")
  companyfacts_parser.add_argument(
    "--ciks",
    help="Comma-separated CIK list. Defaults to SEC_TARGET_CIKS.",
  )
  companyfacts_parser.add_argument(
    "--max-companies",
    type=int,
    default=0,
    help="Optional cap after parsing the input list.",
  )
  parse_companyfacts_parser = subparsers.add_parser("parse-sec-companyfacts")
  parse_companyfacts_parser.add_argument(
    "--ciks",
    help="Comma-separated CIK list. Defaults to SEC_TARGET_CIKS.",
  )
  parse_companyfacts_parser.add_argument(
    "--max-companies",
    type=int,
    default=0,
    help="Optional cap after parsing the input list.",
  )
  document_parser = subparsers.add_parser("fetch-sec-filing-documents")
  document_parser.add_argument(
    "--limit",
    type=int,
    default=10,
    help="Maximum number of filing documents to fetch in one run.",
  )
  metrics_parser = subparsers.add_parser("compute-company-metrics")
  metrics_parser.add_argument(
    "--company-ids",
    help="Comma-separated company UUIDs to compute metrics for.",
  )
  price_parser = subparsers.add_parser("sync-price-snapshots")
  price_parser.add_argument(
    "--limit",
    type=int,
    default=0,
    help="Maximum number of securities to fetch prices for (0 = all).",
  )
  screener_parser = subparsers.add_parser("execute-screener")
  screener_parser.add_argument(
    "--screener-id",
    required=True,
    help="UUID of the saved screener to execute.",
  )
  subparsers.add_parser("sync-bps-series")
  subparsers.add_parser("compute-data-quality")
  fred_parser = subparsers.add_parser("sync-fred-series")
  fred_parser.add_argument(
    "--series",
    help="Comma-separated FRED series IDs. Defaults to built-in list.",
  )
  fred_parser.add_argument(
    "--limit",
    type=int,
    default=0,
    help="Maximum number of series to sync (0 = all).",
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

  if args.command == "sync-sec-companyfacts":
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

    summary = run_sync_sec_companyfacts(
      ciks=ciks,
      sec_client=sec_client,
      supabase_client=supabase_client,
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
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "parse-sec-companyfacts":
    ciks: tuple[str, ...] = _resolve_ciks(args.ciks, config)
    if args.max_companies > 0:
      ciks = ciks[: args.max_companies]

    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_parse_sec_companyfacts(
      ciks=ciks,
      supabase_client=supabase_client,
    )
    print(
      json.dumps(
        {
          "fetch_run_id": summary.fetch_run_id,
          "processed_ciks": summary.processed_ciks,
          "succeeded_ciks": summary.succeeded_ciks,
          "failed_ciks": summary.failed_ciks,
          "created_reporting_periods": summary.created_reporting_periods,
          "replayed_reporting_periods": summary.replayed_reporting_periods,
          "created_statements": summary.created_statements,
          "replayed_statements": summary.replayed_statements,
          "created_items": summary.created_items,
          "replayed_items": summary.replayed_items,
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

  if args.command == "compute-company-metrics":
    company_ids: list[str] = _resolve_company_ids(args.company_ids, config)

    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_compute_company_metrics(
      company_ids=company_ids,
      supabase_client=supabase_client,
    )
    print(
      json.dumps(
        {
          "run_id": summary.run_id,
          "processed_companies": summary.processed_companies,
          "succeeded_companies": summary.succeeded_companies,
          "failed_companies": summary.failed_companies,
          "computed_snapshots": summary.computed_snapshots,
          "skipped_snapshots": summary.skipped_snapshots,
          "successful_company_ids": summary.successful_company_ids,
          "failed_company_ids": summary.failed_company_ids,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "sync-price-snapshots":
    if not config.twelve_data_api_key:
      raise ValueError("TWELVE_DATA_API_KEY is required for sync-price-snapshots")

    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_sync_price_snapshots(
      supabase_client=supabase_client,
      http_client=http_client,
      twelve_data_api_key=config.twelve_data_api_key,
      limit=args.limit,
    )
    print(
      json.dumps(
        {
          "processed_securities": summary.processed_securities,
          "succeeded": summary.succeeded,
          "failed": summary.failed,
          "inserted": summary.inserted,
          "failed_tickers": summary.failed_tickers,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "execute-screener":
    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_execute_screener(
      supabase_client=supabase_client,
      screener_id=args.screener_id,
    )
    print(
      json.dumps(
        {
          "screener_id": summary.screener_id,
          "screener_name": summary.screener_name,
          "result_count": summary.result_count,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "compute-data-quality":
    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_compute_data_quality(
      supabase_client=supabase_client,
    )
    print(
      json.dumps(
        {
          "processed_companies": summary.processed_companies,
          "succeeded_companies": summary.succeeded_companies,
          "failed_companies": summary.failed_companies,
          "successful_company_ids": summary.successful_company_ids,
          "failed_company_ids": summary.failed_company_ids,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "sync-fred-series":
    if not config.fred_api_key:
      raise ValueError("FRED_API_KEY is required for sync-fred-series")

    series_ids: tuple[str, ...] | None = None
    if args.series:
      series_ids = tuple(s.strip() for s in args.series.split(",") if s.strip())

    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_sync_fred_series(
      supabase_client=supabase_client,
      http_client=http_client,
      fred_api_key=config.fred_api_key,
      series_ids=series_ids,
      limit=args.limit,
    )
    print(
      json.dumps(
        {
          "processed_series": summary.processed_series,
          "succeeded": summary.succeeded,
          "failed": summary.failed,
          "inserted_observations": summary.inserted_observations,
          "failed_series_ids": summary.failed_series_ids,
        },
        ensure_ascii=True,
        sort_keys=True,
      )
    )
    return 0

  if args.command == "sync-bps-series":
    if not config.bps_api_key:
      raise ValueError("BPS_API_KEY is required for sync-bps-series")

    http_client = HttpClient()
    supabase_client = SupabaseRestClient(
      http_client=http_client,
      supabase_url=config.supabase_url,
      service_role_key=config.supabase_service_role_key,
    )
    summary = run_sync_bps_series(
      supabase_client=supabase_client,
      http_client=http_client,
      bps_api_key=config.bps_api_key,
    )
    print(
      json.dumps(
        {
          "processed_variables": summary.processed_variables,
          "succeeded": summary.succeeded,
          "failed": summary.failed,
          "inserted_observations": summary.inserted_observations,
          "failed_var_ids": summary.failed_var_ids,
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


def _resolve_company_ids(cli_value: str | None, config: WorkerConfig) -> list[str]:
  if cli_value and cli_value.strip():
    return [item.strip() for item in cli_value.split(",") if item.strip()]
  raise ValueError("No company IDs provided. Use --company-ids.")


if __name__ == "__main__":
  sys.exit(main())
