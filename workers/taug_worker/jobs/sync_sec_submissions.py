from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
from typing import Iterable

from ..__init__ import __version__
from ..sec_client import SecClient
from ..supabase_rest import RawSource, SupabaseRestClient


@dataclass(frozen=True)
class SyncSummary:
  fetch_run_id: str
  processed_ciks: int
  succeeded_ciks: int
  failed_ciks: int


def run_sync_sec_submissions(
  *,
  ciks: Iterable[str],
  sec_client: SecClient,
  supabase_client: SupabaseRestClient,
) -> SyncSummary:
  normalized_ciks: list[str] = [cik.zfill(10) for cik in ciks if cik.strip()]
  if not normalized_ciks:
    raise ValueError("At least one CIK is required for sync_sec_submissions")

  source: RawSource = supabase_client.ensure_sec_source()
  fetch_run_id: str = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="filing_discovery",
    job_scope={
      "source": source.code,
      "record_type": "sec_submissions",
      "cik_count": len(normalized_ciks),
      "ciks": normalized_ciks,
    },
    worker_version=__version__,
  )

  success_count: int = 0
  failure_count: int = 0

  try:
    for cik in normalized_ciks:
      try:
        payload: dict[str, object] = sec_client.fetch_submissions(cik)
        canonical_bytes: bytes = sec_client.canonical_payload_bytes(payload)
        payload_hash: str = sha256(canonical_bytes).hexdigest()
        source_record_key: str = f"sec_submissions:{cik}"
        ticker: str | None = _extract_primary_ticker(payload)

        supabase_client.insert_raw_record(
          raw_source_id=source.id,
          fetch_run_id=fetch_run_id,
          record_type="sec_submissions",
          source_record_key=source_record_key,
          source_entity_key=cik,
          payload_json=payload,
          payload_hash=payload_hash,
          metadata={
            "cik": cik,
            "ticker": ticker,
            "worker_version": __version__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="raw_record_ingested",
          entity_type="raw_record",
          entity_id=source_record_key,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "record_type": "sec_submissions",
            "cik": cik,
            "ticker": ticker,
            "payload_hash": payload_hash,
          },
        )
        success_count += 1
      except Exception as exc:
        failure_count += 1
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule="sec_submissions_fetch",
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "worker_version": __version__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="raw_record_ingestion_failed",
          entity_type="sec_company",
          entity_id=cik,
          severity="error",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "message": str(exc),
          },
        )

    final_status: str = "success" if failure_count == 0 else "partial"
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status=final_status,
      metadata={
        "processed_ciks": len(normalized_ciks),
        "succeeded_ciks": success_count,
        "failed_ciks": failure_count,
      },
    )
  except Exception as exc:
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="failed",
      error_code="worker_crash",
      error_message=str(exc),
      metadata={
        "processed_ciks": len(normalized_ciks),
        "succeeded_ciks": success_count,
        "failed_ciks": failure_count,
      },
    )
    raise

  return SyncSummary(
    fetch_run_id=fetch_run_id,
    processed_ciks=len(normalized_ciks),
    succeeded_ciks=success_count,
    failed_ciks=failure_count,
  )


def _extract_primary_ticker(payload: dict[str, object]) -> str | None:
  tickers: object = payload.get("tickers")
  if isinstance(tickers, list) and tickers:
    first: object = tickers[0]
    if isinstance(first, str) and first.strip():
      return first.strip()
  return None
