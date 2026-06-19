from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timezone
from hashlib import sha256
from typing import Iterable

from ..__init__ import __version__
from ..sec_client import SecClient, SecClientError, SecSubmissionsParseError
from ..supabase_rest import RawSource, SupabaseRestClient, UpsertResult
from ..validators.sec_submissions import (
  ValidationFailure,
  validate_sec_submissions_payload,
)


@dataclass(frozen=True)
class SyncSummary:
  fetch_run_id: str
  processed_ciks: int
  succeeded_ciks: int
  failed_ciks: int
  created_raw_records: int
  replayed_raw_records: int
  created_filings: int
  replayed_filings: int
  created_filing_versions: int
  replayed_filing_versions: int
  successful_cik_ids: tuple[str, ...]
  failed_cik_ids: tuple[str, ...]


@dataclass(frozen=True)
class FilingNormalizationResult:
  created_filings: int
  replayed_filings: int
  created_filing_versions: int
  replayed_filing_versions: int


@dataclass(frozen=True)
class FilingSanityFailure:
  code: str
  message: str
  details: dict[str, object]


def run_sync_sec_submissions(
  *,
  ciks: Iterable[str],
  sec_client: SecClient,
  supabase_client: SupabaseRestClient,
  max_filings_per_company: int,
) -> SyncSummary:
  normalized_ciks: list[str] = [cik.zfill(10) for cik in ciks if cik.strip()]
  if not normalized_ciks:
    raise ValueError("At least one CIK is required for sync_sec_submissions")

  source: RawSource = supabase_client.ensure_sec_source()
  checkpoint_scope: dict[str, object] = {
    "ciks": normalized_ciks,
    "job_type": "filing_discovery",
  }
  checkpoint_scope_key: str = supabase_client.build_checkpoint_scope_key(
    job_type="filing_discovery",
    scope=checkpoint_scope,
  )
  fetch_run_id: str = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="filing_discovery",
    job_scope={
      "source": source.code,
      "record_type": "sec_submissions",
      "cik_count": len(normalized_ciks),
      "ciks": normalized_ciks,
      "checkpoint_scope_key": checkpoint_scope_key,
    },
    worker_version=__version__,
  )

  success_count: int = 0
  failure_count: int = 0
  created_raw_records: int = 0
  replayed_raw_records: int = 0
  created_filings: int = 0
  replayed_filings: int = 0
  created_filing_versions: int = 0
  replayed_filing_versions: int = 0
  successful_cik_ids: list[str] = []
  failed_cik_ids: list[str] = []

  try:
    for cik in normalized_ciks:
      try:
        payload: dict[str, object] = sec_client.fetch_submissions(cik)
        canonical_bytes: bytes = sec_client.canonical_payload_bytes(payload)
        payload_hash: str = sha256(canonical_bytes).hexdigest()
        source_record_key: str = f"sec_submissions:{cik}"
        ticker: str | None = _extract_primary_ticker(payload)
        company_name: str = _extract_company_name(payload, cik)

        raw_record: UpsertResult = supabase_client.insert_raw_record(
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
        if raw_record.created:
          created_raw_records += 1
        else:
          replayed_raw_records += 1
          supabase_client.insert_validation_event(
            entity_type="raw_record",
            entity_id=raw_record.id,
            validation_rule="sec_submissions_duplicate_detection",
            status="passed",
            message=(
              "Duplicate SEC submissions payload detected by "
              "source_record_key and payload_hash; reused existing raw_record."
            ),
            payload={
              "source": source.code,
              "worker_version": __version__,
              "cik": cik,
              "source_record_key": source_record_key,
              "payload_hash": payload_hash,
            },
          )
          supabase_client.insert_audit_event(
            event_type="raw_record_duplicate_detected",
            entity_type="raw_record",
            entity_id=raw_record.id,
            severity="info",
            reference_type="raw_fetch_run",
            reference_id=fetch_run_id,
            payload={
              "source": source.code,
              "cik": cik,
              "source_record_key": source_record_key,
              "payload_hash": payload_hash,
            },
          )
        payload_validation_failures: tuple[ValidationFailure, ...] = (
          validate_sec_submissions_payload(payload)
        )
        if payload_validation_failures:
          failure_payload: dict[str, object] = {
            "source": source.code,
            "worker_version": __version__,
            "raw_record_id": raw_record.id,
            "failure_codes": [failure.code for failure in payload_validation_failures],
            "failures": [
              {
                "code": failure.code,
                "message": failure.message,
                "details": failure.details,
              }
              for failure in payload_validation_failures
            ],
          }
          supabase_client.insert_validation_event(
            entity_type="raw_record",
            entity_id=raw_record.id,
            validation_rule="sec_submissions_required_keys",
            status="failed",
            message=payload_validation_failures[0].message,
            payload=failure_payload,
          )
          supabase_client.insert_audit_event(
            event_type="raw_record_validation_failed",
            entity_type="raw_record",
            entity_id=raw_record.id,
            severity="error",
            reference_type="raw_fetch_run",
            reference_id=fetch_run_id,
            payload=failure_payload,
          )
          raise ValueError(
            "SEC submissions payload validation failed: "
            + ", ".join(failure.code for failure in payload_validation_failures)
          )
        canonical_security = supabase_client.ensure_canonical_security(
          cik=cik,
          ticker=ticker,
          company_name=company_name,
        )
        normalization_result: FilingNormalizationResult = _normalize_filing_discovery(
          payload=payload,
          cik=cik,
          company_id=canonical_security.company_id,
          raw_source_id=source.id,
          raw_record_id=raw_record.id,
          supabase_client=supabase_client,
          max_filings_per_company=max_filings_per_company,
        )
        created_filings += normalization_result.created_filings
        replayed_filings += normalization_result.replayed_filings
        created_filing_versions += normalization_result.created_filing_versions
        replayed_filing_versions += normalization_result.replayed_filing_versions
        supabase_client.insert_audit_event(
          event_type="raw_record_ingested" if raw_record.created else "raw_record_replayed",
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
            "raw_record_id": raw_record.id,
            "raw_record_created": raw_record.created,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            "created_filings": normalization_result.created_filings,
            "replayed_filings": normalization_result.replayed_filings,
            "created_filing_versions": normalization_result.created_filing_versions,
            "replayed_filing_versions": normalization_result.replayed_filing_versions,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_company_processed",
          entity_type="sec_company",
          entity_id=cik,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "ticker": ticker,
            "raw_record_id": raw_record.id,
            "created_raw_record": raw_record.created,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            "created_filings": normalization_result.created_filings,
            "replayed_filings": normalization_result.replayed_filings,
            "created_filing_versions": normalization_result.created_filing_versions,
            "replayed_filing_versions": normalization_result.replayed_filing_versions,
          },
        )
        successful_cik_ids.append(cik)
        success_count += 1
      except Exception as exc:
        failure_count += 1
        failed_cik_ids.append(cik)
        validation_rule: str = "sec_submissions_fetch"
        if isinstance(exc, SecSubmissionsParseError):
          validation_rule = "sec_submissions_payload_parse"
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule=validation_rule,
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "worker_version": __version__,
            "error_code": exc.code if isinstance(exc, SecClientError) else None,
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
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_raw_records": created_raw_records,
          "replayed_raw_records": replayed_raw_records,
          "created_filings": created_filings,
          "replayed_filings": replayed_filings,
          "created_filing_versions": created_filing_versions,
          "replayed_filing_versions": replayed_filing_versions,
        },
      )
    if failure_count == 0:
      supabase_client.upsert_ingestion_checkpoint(
        raw_source_id=source.id,
        job_type="filing_discovery",
        checkpoint_scope_key=checkpoint_scope_key,
        last_success_fetch_run_id=fetch_run_id,
        checkpoint_data={
          "source": source.code,
          "scope": checkpoint_scope,
          "processed_ciks": len(normalized_ciks),
          "succeeded_ciks": success_count,
          "failed_ciks": failure_count,
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_raw_records": created_raw_records,
          "replayed_raw_records": replayed_raw_records,
          "created_filings": created_filings,
          "replayed_filings": replayed_filings,
          "created_filing_versions": created_filing_versions,
          "replayed_filing_versions": replayed_filing_versions,
          "checkpointed_at": datetime.now(timezone.utc).isoformat(),
        },
      )
    supabase_client.insert_audit_event(
      event_type="raw_fetch_run_completed" if failure_count == 0 else "raw_fetch_run_partial",
      entity_type="raw_fetch_run",
      entity_id=fetch_run_id,
      severity="info" if failure_count == 0 else "warning",
      payload={
        "source": source.code,
        "processed_ciks": len(normalized_ciks),
        "succeeded_ciks": success_count,
        "failed_ciks": failure_count,
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_raw_records": created_raw_records,
        "replayed_raw_records": replayed_raw_records,
        "created_filings": created_filings,
        "replayed_filings": replayed_filings,
        "created_filing_versions": created_filing_versions,
        "replayed_filing_versions": replayed_filing_versions,
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
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_raw_records": created_raw_records,
          "replayed_raw_records": replayed_raw_records,
          "created_filings": created_filings,
          "replayed_filings": replayed_filings,
          "created_filing_versions": created_filing_versions,
          "replayed_filing_versions": replayed_filing_versions,
        },
      )
    supabase_client.insert_audit_event(
      event_type="raw_fetch_run_failed",
      entity_type="raw_fetch_run",
      entity_id=fetch_run_id,
      severity="error",
      payload={
        "source": source.code,
        "message": str(exc),
        "processed_ciks": len(normalized_ciks),
        "succeeded_ciks": success_count,
        "failed_ciks": failure_count,
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
      },
    )
    raise

  return SyncSummary(
    fetch_run_id=fetch_run_id,
    processed_ciks=len(normalized_ciks),
    succeeded_ciks=success_count,
    failed_ciks=failure_count,
    created_raw_records=created_raw_records,
    replayed_raw_records=replayed_raw_records,
    created_filings=created_filings,
    replayed_filings=replayed_filings,
    created_filing_versions=created_filing_versions,
    replayed_filing_versions=replayed_filing_versions,
    successful_cik_ids=tuple(successful_cik_ids),
    failed_cik_ids=tuple(failed_cik_ids),
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
  cik: str,
  company_id: str,
  raw_source_id: int,
  raw_record_id: str,
  supabase_client: SupabaseRestClient,
  max_filings_per_company: int,
) -> FilingNormalizationResult:
  filings_section: object = payload.get("filings")
  if not isinstance(filings_section, dict):
    return FilingNormalizationResult(
      created_filings=0,
      replayed_filings=0,
      created_filing_versions=0,
      replayed_filing_versions=0,
    )
  recent: object = filings_section.get("recent")
  if not isinstance(recent, dict):
    return FilingNormalizationResult(
      created_filings=0,
      replayed_filings=0,
      created_filing_versions=0,
      replayed_filing_versions=0,
    )

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
  if max_filings_per_company > 0:
    filing_count = min(filing_count, max_filings_per_company)
  created_filings: int = 0
  replayed_filings: int = 0
  created_filing_versions: int = 0
  replayed_filing_versions: int = 0

  for index in range(filing_count):
    filing_key: str = accession_numbers[index].strip()
    filing_date: str = filing_dates[index].strip()
    filing_type: str = filing_types[index].strip()
    raw_acceptance_datetime: str | None = (
      acceptance_datetimes[index] if index < len(acceptance_datetimes) else None
    )
    acceptance_datetime: str | None = _normalize_sec_acceptance_datetime(
      raw_acceptance_datetime
    )
    raw_report_date: str | None = report_dates[index] if index < len(report_dates) else None
    report_date: str | None = _normalize_optional_date(raw_report_date)
    primary_document: str | None = (
      primary_documents[index].strip()
      if index < len(primary_documents) and primary_documents[index].strip()
      else None
    )
    if not filing_key or not filing_date or not filing_type:
      continue

    filing_result: UpsertResult = supabase_client.upsert_filing(
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
    filing_record = supabase_client.get_filing_record(filing_id=filing_result.id)
    if filing_record.company_id != company_id:
      failure_payload: dict[str, object] = {
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_key": filing_record.filing_key,
        "expected_company_id": company_id,
        "actual_company_id": filing_record.company_id,
        "raw_record_id": raw_record_id,
      }
      supabase_client.insert_validation_event(
        entity_type="filing",
        entity_id=filing_result.id,
        validation_rule="sec_filing_company_mapping",
        status="failed",
        message="Resolved filing company_id does not match canonical company mapping.",
        payload=failure_payload,
      )
      supabase_client.insert_audit_event(
        event_type="filing_company_mapping_failed",
        entity_type="filing",
        entity_id=filing_result.id,
        severity="error",
        payload=failure_payload,
      )
      raise ValueError(
        "SEC filing company mapping validation failed: "
        f"filing_id={filing_result.id} expected_company_id={company_id} "
        f"actual_company_id={filing_record.company_id}"
      )
    supabase_client.insert_validation_event(
      entity_type="filing",
      entity_id=filing_result.id,
      validation_rule="sec_filing_company_mapping",
      status="passed",
      message="Resolved filing company_id matches canonical company mapping.",
      payload={
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_key": filing_record.filing_key,
        "company_id": company_id,
        "raw_record_id": raw_record_id,
      },
    )
    sanity_failures: tuple[FilingSanityFailure, ...] = _validate_filing_temporal_sanity(
      filing_date=filing_date,
      raw_acceptance_datetime=raw_acceptance_datetime,
      acceptance_datetime=acceptance_datetime,
      report_date=report_date,
    )
    if sanity_failures:
      failure_payload: dict[str, object] = {
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_key": filing_record.filing_key,
        "filing_date": filing_date,
        "raw_acceptance_datetime": raw_acceptance_datetime,
        "acceptance_datetime": acceptance_datetime,
        "report_date": report_date,
        "raw_record_id": raw_record_id,
        "failure_codes": [failure.code for failure in sanity_failures],
        "failures": [
          {
            "code": failure.code,
            "message": failure.message,
            "details": failure.details,
          }
          for failure in sanity_failures
        ],
      }
      supabase_client.insert_validation_event(
        entity_type="filing",
        entity_id=filing_result.id,
        validation_rule="sec_filing_temporal_sanity",
        status="failed",
        message=sanity_failures[0].message,
        payload=failure_payload,
      )
      supabase_client.insert_audit_event(
        event_type="filing_temporal_sanity_failed",
        entity_type="filing",
        entity_id=filing_result.id,
        severity="error",
        payload=failure_payload,
      )
      raise ValueError(
        "SEC filing temporal sanity validation failed: "
        + ", ".join(failure.code for failure in sanity_failures)
      )
    supabase_client.insert_validation_event(
      entity_type="filing",
      entity_id=filing_result.id,
      validation_rule="sec_filing_temporal_sanity",
      status="passed",
      message="Resolved filing dates and acceptance datetime passed temporal sanity checks.",
      payload={
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_key": filing_record.filing_key,
        "filing_date": filing_date,
        "raw_acceptance_datetime": raw_acceptance_datetime,
        "acceptance_datetime": acceptance_datetime,
        "report_date": report_date,
        "raw_record_id": raw_record_id,
      },
    )
    if filing_result.created:
      created_filings += 1
    else:
      replayed_filings += 1
    filing_version_result: UpsertResult = supabase_client.upsert_filing_version(
      filing_id=filing_result.id,
      raw_record_id=raw_record_id,
      parser_version=__version__,
      metadata={
        "source": "sec_edgar",
        "filing_key": filing_key,
        "primary_document": primary_document,
      },
    )
    filing_version_record = supabase_client.get_filing_version_record(
      filing_version_id=filing_version_result.id,
    )
    version_failure_codes: list[str] = []
    if filing_version_record.filing_id != filing_result.id:
      version_failure_codes.append("filing_id_mismatch")
    if filing_version_record.raw_record_id != raw_record_id:
      version_failure_codes.append("raw_record_id_mismatch")
    if filing_version_record.version_number != 1:
      version_failure_codes.append("unexpected_version_number")
    if filing_version_record.status not in ("active", "superseded"):
      version_failure_codes.append("unexpected_status")
    if version_failure_codes:
      failure_payload: dict[str, object] = {
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_version_id": filing_version_result.id,
        "raw_record_id": raw_record_id,
        "expected_version_number": 1,
        "actual_version_number": filing_version_record.version_number,
        "expected_status": "active",
        "actual_status": filing_version_record.status,
        "expected_filing_id": filing_result.id,
        "actual_filing_id": filing_version_record.filing_id,
        "expected_raw_record_id": raw_record_id,
        "actual_raw_record_id": filing_version_record.raw_record_id,
        "failure_codes": version_failure_codes,
      }
      supabase_client.insert_validation_event(
        entity_type="filing_version",
        entity_id=filing_version_result.id,
        validation_rule="sec_filing_version_linkage",
        status="failed",
        message="Resolved filing_version linkage does not match expected filing/version invariants.",
        payload=failure_payload,
      )
      supabase_client.insert_audit_event(
        event_type="filing_version_linkage_failed",
        entity_type="filing_version",
        entity_id=filing_version_result.id,
        severity="error",
        payload=failure_payload,
      )
      raise ValueError(
        "SEC filing version linkage validation failed: "
        + ", ".join(version_failure_codes)
      )
    supabase_client.insert_validation_event(
      entity_type="filing_version",
      entity_id=filing_version_result.id,
      validation_rule="sec_filing_version_linkage",
      status="passed",
      message="Resolved filing_version linkage matches expected filing/version invariants.",
      payload={
        "source": "sec_edgar",
        "cik": cik,
        "filing_id": filing_result.id,
        "filing_version_id": filing_version_result.id,
        "raw_record_id": raw_record_id,
        "version_number": filing_version_record.version_number,
        "status": filing_version_record.status,
      },
    )
    _maybe_link_amendment_version(
      filing_record=filing_record,
      filing_version_record=filing_version_record,
      cik=cik,
      supabase_client=supabase_client,
    )
    if filing_version_result.created:
      created_filing_versions += 1
    else:
      replayed_filing_versions += 1

  return FilingNormalizationResult(
    created_filings=created_filings,
    replayed_filings=replayed_filings,
    created_filing_versions=created_filing_versions,
    replayed_filing_versions=replayed_filing_versions,
  )


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


def _validate_filing_temporal_sanity(
  *,
  filing_date: str,
  raw_acceptance_datetime: str | None,
  acceptance_datetime: str | None,
  report_date: str | None,
) -> tuple[FilingSanityFailure, ...]:
  failures: list[FilingSanityFailure] = []

  parsed_filing_date: date | None = _parse_iso_date(filing_date)
  if parsed_filing_date is None:
    failures.append(
      FilingSanityFailure(
        code="invalid_filing_date",
        message="Filing date is not a valid ISO date.",
        details={"filing_date": filing_date},
      )
    )
    return tuple(failures)

  if raw_acceptance_datetime is not None and raw_acceptance_datetime.strip():
    if acceptance_datetime is None:
      failures.append(
        FilingSanityFailure(
          code="invalid_acceptance_datetime",
          message="Acceptance datetime is present but could not be normalized.",
          details={"raw_acceptance_datetime": raw_acceptance_datetime},
        )
      )
    else:
      parsed_acceptance_datetime: datetime | None = _parse_iso_datetime(acceptance_datetime)
      if parsed_acceptance_datetime is None:
        failures.append(
          FilingSanityFailure(
            code="invalid_normalized_acceptance_datetime",
            message="Normalized acceptance datetime is not a valid ISO timestamp.",
            details={"acceptance_datetime": acceptance_datetime},
          )
        )
      elif parsed_acceptance_datetime.date() < parsed_filing_date:
        failures.append(
          FilingSanityFailure(
            code="acceptance_before_filing_date",
            message="Acceptance datetime occurs before filing_date.",
            details={
              "filing_date": filing_date,
              "acceptance_datetime": acceptance_datetime,
            },
          )
        )

  if report_date is not None:
    parsed_report_date: date | None = _parse_iso_date(report_date)
    if parsed_report_date is None:
      failures.append(
        FilingSanityFailure(
          code="invalid_report_date",
          message="Report date is not a valid ISO date.",
          details={"report_date": report_date},
        )
      )
    elif parsed_report_date > parsed_filing_date:
      failures.append(
        FilingSanityFailure(
          code="report_date_after_filing_date",
          message="Report date occurs after filing_date.",
          details={
            "report_date": report_date,
            "filing_date": filing_date,
          },
        )
      )

  return tuple(failures)


def _parse_iso_date(value: str) -> date | None:
  try:
    return date.fromisoformat(value)
  except ValueError:
    return None


def _parse_iso_datetime(value: str) -> datetime | None:
  try:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))
  except ValueError:
    return None


def _maybe_link_amendment_version(
  *,
  filing_record: FilingRecord,
  filing_version_record: FilingVersionRecord,
  cik: str,
  supabase_client: SupabaseRestClient,
) -> None:
  if not filing_record.is_amendment:
    return

  base_filing_type: str = _base_filing_type(filing_record.filing_type)
  candidates = supabase_client.list_filing_candidates(
    company_id=filing_record.company_id,
    raw_source_id=filing_record.raw_source_id,
    filing_date_lte=filing_record.filing_date,
    exclude_filing_id=filing_record.id,
    limit=200,
  )

  prior_filing = None
  for candidate in candidates:
    if _base_filing_type(candidate.filing_type) != base_filing_type:
      continue
    if filing_record.report_date is not None:
      if candidate.report_date != filing_record.report_date:
        continue
    elif candidate.report_date is not None:
      continue
    prior_filing = candidate
    break

  if prior_filing is None:
    return

  prior_active_version = supabase_client.get_active_filing_version_by_filing(
    filing_id=prior_filing.id,
  )
  if prior_active_version is None:
    return
  if prior_active_version.id == filing_version_record.id:
    return

  supabase_client.update_filing_version_supersession(
    filing_version_id=filing_version_record.id,
    supersedes_filing_version_id=prior_active_version.id,
    is_restated=True,
    status="active",
  )
  supabase_client.update_filing_version_supersession(
    filing_version_id=prior_active_version.id,
    superseded_by_filing_version_id=filing_version_record.id,
    status="superseded",
  )
  supabase_client.insert_restatement_event(
    entity_type="filing_version",
    entity_id=filing_version_record.id,
    prior_reference_id=prior_active_version.id,
    new_reference_id=filing_version_record.id,
    detection_method="sec_amendment_form",
    status="validated",
    payload={
      "source": "sec_edgar",
      "cik": cik,
      "base_filing_type": base_filing_type,
      "amendment_filing_id": filing_record.id,
      "prior_filing_id": prior_filing.id,
    },
  )
  supabase_client.insert_audit_event(
    event_type="filing_version_amendment_linked",
    entity_type="filing_version",
    entity_id=filing_version_record.id,
    severity="info",
    payload={
      "source": "sec_edgar",
      "cik": cik,
      "base_filing_type": base_filing_type,
      "supersedes_filing_version_id": prior_active_version.id,
      "prior_filing_id": prior_filing.id,
      "amendment_filing_id": filing_record.id,
    },
  )


def _base_filing_type(filing_type: str) -> str:
  normalized: str = filing_type.strip().upper()
  if normalized.endswith("/A"):
    normalized = normalized[:-2].strip()
  if normalized.endswith("-A"):
    normalized = normalized[:-2].strip()
  normalized = normalized.replace("SCHEDULE 13G", "13G")
  normalized = normalized.replace("SC 13G", "13G")
  normalized = normalized.replace("SCHEDULE 13D", "13D")
  normalized = normalized.replace("SC 13D", "13D")
  return normalized


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
