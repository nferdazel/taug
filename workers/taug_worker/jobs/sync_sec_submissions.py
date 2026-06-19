from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
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
        company_name: str = _extract_company_name(payload, cik)

        raw_record_id: str = supabase_client.insert_raw_record(
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
        canonical_security = supabase_client.ensure_canonical_security(
          cik=cik,
          ticker=ticker,
          company_name=company_name,
        )
        discovered_filings: int = _normalize_filing_discovery(
          payload=payload,
          company_id=canonical_security.company_id,
          raw_source_id=source.id,
          raw_record_id=raw_record_id,
          supabase_client=supabase_client,
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
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            "discovered_filings": discovered_filings,
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


def _extract_company_name(payload: dict[str, object], fallback_cik: str) -> str:
  company_name: object = payload.get("name")
  if isinstance(company_name, str) and company_name.strip():
    return company_name.strip()
  return f"SEC Company {fallback_cik}"


def _normalize_filing_discovery(
  *,
  payload: dict[str, object],
  company_id: str,
  raw_source_id: int,
  raw_record_id: str,
  supabase_client: SupabaseRestClient,
) -> int:
  filings_section: object = payload.get("filings")
  if not isinstance(filings_section, dict):
    return 0
  recent: object = filings_section.get("recent")
  if not isinstance(recent, dict):
    return 0

  accession_numbers: list[str] = _extract_string_array(recent.get("accessionNumber"))
  filing_dates: list[str] = _extract_string_array(recent.get("filingDate"))
  filing_types: list[str] = _extract_string_array(recent.get("form"))
  acceptance_datetimes: list[str] = _extract_string_array(
    recent.get("acceptanceDateTime")
  )
  report_dates: list[str] = _extract_string_array(recent.get("reportDate"))
  primary_documents: list[str] = _extract_string_array(recent.get("primaryDocument"))

  filing_count: int = min(
    len(accession_numbers),
    len(filing_dates),
    len(filing_types),
  )
  created_count: int = 0

  for index in range(filing_count):
    filing_key: str = accession_numbers[index].strip()
    filing_date: str = filing_dates[index].strip()
    filing_type: str = filing_types[index].strip()
    acceptance_datetime: str | None = _normalize_sec_acceptance_datetime(
      acceptance_datetimes[index] if index < len(acceptance_datetimes) else None
    )
    report_date: str | None = _normalize_optional_date(
      report_dates[index] if index < len(report_dates) else None
    )
    primary_document: str | None = (
      primary_documents[index].strip()
      if index < len(primary_documents) and primary_documents[index].strip()
      else None
    )
    if not filing_key or not filing_date or not filing_type:
      continue

    filing_id: str = supabase_client.upsert_filing(
      company_id=company_id,
      raw_source_id=raw_source_id,
      filing_type=filing_type,
      filing_key=filing_key,
      filing_date=filing_date,
      acceptance_datetime=acceptance_datetime,
      report_date=report_date,
      is_amendment=_is_amendment_form(filing_type),
      metadata={
        "primary_document": primary_document,
        "source": "sec_edgar",
        "cik": payload.get("cik", cik),
      },
    )
    supabase_client.upsert_filing_version(
      filing_id=filing_id,
      raw_record_id=raw_record_id,
      parser_version=__version__,
      metadata={
        "source": "sec_edgar",
        "filing_key": filing_key,
        "primary_document": primary_document,
      },
    )
    created_count += 1

  return created_count


def _extract_string_array(value: object) -> list[str]:
  if not isinstance(value, list):
    return []
  result: list[str] = []
  for item in value:
    if isinstance(item, str):
      result.append(item)
    else:
      result.append("" if item is None else str(item))
  return result


def _normalize_optional_date(value: str | None) -> str | None:
  if value is None:
    return None
  normalized: str = value.strip()
  return normalized or None


def _normalize_sec_acceptance_datetime(value: str | None) -> str | None:
  if value is None:
    return None
  normalized: str = value.strip()
  if not normalized:
    return None

  if "T" in normalized:
    try:
      parsed = datetime.fromisoformat(normalized.replace("Z", "+00:00"))
      return parsed.astimezone(timezone.utc).isoformat()
    except ValueError:
      return None

  if len(normalized) == 14 and normalized.isdigit():
    parsed = datetime.strptime(normalized, "%Y%m%d%H%M%S")
    return parsed.replace(tzinfo=timezone.utc).isoformat()

  return None


def _is_amendment_form(filing_type: str) -> bool:
  normalized: str = filing_type.upper()
  return normalized.endswith("/A") or normalized.endswith("-A")
