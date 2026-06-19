from __future__ import annotations

import argparse
import json
import sys

from .config import WorkerConfig
from .http_client import HttpClient
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
    )
    print(
      json.dumps(
        {
          "fetch_run_id": summary.fetch_run_id,
          "processed_ciks": summary.processed_ciks,
          "succeeded_ciks": summary.succeeded_ciks,
          "failed_ciks": summary.failed_ciks,
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
