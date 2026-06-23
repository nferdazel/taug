from __future__ import annotations

import time
from dataclasses import dataclass
from hashlib import sha256
from typing import Any, Iterable

from ..__init__ import __version__
from ..sec_client import SecClient, SecClientError, SecCompanyfactsParseError
from ..supabase_rest import RawSource, SupabaseRestClient, UpsertResult
from ..validators.sec_companyfacts import (
  ValidationFailure,
  validate_sec_companyfacts_payload,
)


@dataclass(frozen=True)
class SyncCompanyfactsSummary:
  fetch_run_id: str
  processed_ciks: int
  succeeded_ciks: int
  failed_ciks: int
  created_raw_records: int
  replayed_raw_records: int
  successful_cik_ids: tuple[str, ...]
  failed_cik_ids: tuple[str, ...]


def run_sync_sec_companyfacts(
  *,
  ciks: Iterable[str],
  sec_client: SecClient,
  supabase_client: SupabaseRestClient,
) -> SyncCompanyfactsSummary:
  normalized_ciks: list[str] = [cik.zfill(10) for cik in ciks if cik.strip()]
  if not normalized_ciks:
    raise ValueError("At least one CIK is required for sync_sec_companyfacts")

  source: RawSource = supabase_client.ensure_sec_source()
  checkpoint_scope: dict[str, object] = {
    "ciks": normalized_ciks,
    "job_type": "companyfacts_sync",
  }
  checkpoint_scope_key: str = supabase_client.build_checkpoint_scope_key(
    job_type="companyfacts_sync",
    scope=checkpoint_scope,
  )
  fetch_run_id: str = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="companyfacts_sync",
    job_scope={
      "source": source.code,
      "record_type": "sec_companyfacts",
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
  successful_cik_ids: list[str] = []
  failed_cik_ids: list[str] = []

  try:
    for i, cik in enumerate(normalized_ciks):
      try:
        # Add delay between companies to avoid overwhelming Supabase free tier
        if i > 0 and i % 5 == 0:
          time.sleep(2)  # 2 second pause every 5 companies

        payload: dict[str, object] = sec_client.fetch_companyfacts(cik)
        canonical_bytes: bytes = sec_client.canonical_payload_bytes(payload)
        payload_hash: str = sha256(canonical_bytes).hexdigest()
        entity_name: str = _extract_entity_name(payload, cik)
        ticker: str | None = _extract_primary_ticker(payload)
        fact_counts: dict[str, int] = _count_companyfacts(payload)
        source_record_key: str = f"sec_companyfacts:{cik}"

        raw_record: UpsertResult = supabase_client.insert_raw_record(
          raw_source_id=source.id,
          fetch_run_id=fetch_run_id,
          record_type="sec_companyfacts",
          source_record_key=source_record_key,
          source_entity_key=cik,
          payload_json=payload,
          payload_hash=payload_hash,
          metadata={
            "cik": cik,
            "ticker": ticker,
            "entity_name": entity_name,
            "worker_version": __version__,
            **fact_counts,
          },
        )
        if raw_record.created:
          created_raw_records += 1
        else:
          replayed_raw_records += 1
          supabase_client.insert_validation_event(
            entity_type="raw_record",
            entity_id=raw_record.id,
            validation_rule="sec_companyfacts_duplicate_detection",
            status="passed",
            message=(
              "Duplicate SEC companyfacts payload detected by "
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
              "record_type": "sec_companyfacts",
              "cik": cik,
              "source_record_key": source_record_key,
              "payload_hash": payload_hash,
            },
          )

        payload_validation_failures: tuple[ValidationFailure, ...] = (
          validate_sec_companyfacts_payload(payload)
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
            validation_rule="sec_companyfacts_required_keys",
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
            "SEC companyfacts payload validation failed: "
            + ", ".join(failure.code for failure in payload_validation_failures)
          )

        canonical_security = supabase_client.ensure_canonical_security(
          cik=cik,
          ticker=ticker,
          company_name=entity_name,
        )
        supabase_client.insert_audit_event(
          event_type="raw_record_ingested" if raw_record.created else "raw_record_replayed",
          entity_type="raw_record",
          entity_id=source_record_key,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "record_type": "sec_companyfacts",
            "cik": cik,
            "ticker": ticker,
            "payload_hash": payload_hash,
            "raw_record_id": raw_record.id,
            "raw_record_created": raw_record.created,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            **fact_counts,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_processed",
          entity_type="sec_company",
          entity_id=cik,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "ticker": ticker,
            "entity_name": entity_name,
            "raw_record_id": raw_record.id,
            "created_raw_record": raw_record.created,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            **fact_counts,
          },
        )
        supabase_client.insert_validation_event(
          entity_type="raw_record",
          entity_id=raw_record.id,
          validation_rule="sec_companyfacts_required_keys",
          status="passed",
          message="SEC companyfacts payload passed required-key and unit-shape validation.",
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            **fact_counts,
          },
        )
        successful_cik_ids.append(cik)
        success_count += 1
      except Exception as exc:
        failure_count += 1
        failed_cik_ids.append(cik)
        validation_rule: str = "sec_companyfacts_fetch"
        if isinstance(exc, SecCompanyfactsParseError):
          validation_rule = "sec_companyfacts_payload_parse"
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule=validation_rule,
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "error_type": type(exc).__name__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_sync_failed",
          entity_type="sec_company",
          entity_id=cik,
          severity="error",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "error_type": type(exc).__name__,
            "error_message": str(exc),
          },
        )
        continue

    run_status: str = "success"
    error_code: str | None = None
    error_message: str | None = None
    if success_count == 0:
      run_status = "failed"
      error_code = "sec_companyfacts_sync_failed"
      error_message = "All requested CIKs failed during SEC companyfacts sync."
    elif failure_count > 0:
      run_status = "partial"
      error_code = "sec_companyfacts_sync_partial_failure"
      error_message = "One or more requested CIKs failed during SEC companyfacts sync."

    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status=run_status,
      error_code=error_code,
      error_message=error_message,
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_raw_records": created_raw_records,
        "replayed_raw_records": replayed_raw_records,
      },
    )
    if success_count > 0:
      supabase_client.upsert_ingestion_checkpoint(
        raw_source_id=source.id,
        job_type="companyfacts_sync",
        checkpoint_scope_key=checkpoint_scope_key,
        last_success_fetch_run_id=fetch_run_id,
        checkpoint_data={
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_raw_records": created_raw_records,
          "replayed_raw_records": replayed_raw_records,
          "processed_cik_count": len(normalized_ciks),
        },
      )

    return SyncCompanyfactsSummary(
      fetch_run_id=fetch_run_id,
      processed_ciks=len(normalized_ciks),
      succeeded_ciks=success_count,
      failed_ciks=failure_count,
      created_raw_records=created_raw_records,
      replayed_raw_records=replayed_raw_records,
      successful_cik_ids=tuple(successful_cik_ids),
      failed_cik_ids=tuple(failed_cik_ids),
    )
  except Exception as exc:
    error_code: str = (
      exc.code if isinstance(exc, SecClientError) else "sec_companyfacts_sync_failed"
    )
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="failed",
      error_code=error_code,
      error_message=str(exc),
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_raw_records": created_raw_records,
        "replayed_raw_records": replayed_raw_records,
      },
    )
    raise


def _extract_entity_name(payload: dict[str, object], fallback_cik: str) -> str:
  value: object = payload.get("entityName")
  if isinstance(value, str) and value.strip():
    return value.strip()
  return fallback_cik


def _extract_primary_ticker(payload: dict[str, object]) -> str | None:
  entity_name: object = payload.get("entityName")
  if not isinstance(entity_name, str):
    return None
  if "(" not in entity_name or ")" not in entity_name:
    return None
  candidate: str = entity_name.rsplit("(", 1)[-1].rstrip(")").strip()
  if not candidate or len(candidate) > 10 or " " in candidate:
    return None
  return candidate.upper()


def _count_companyfacts(payload: dict[str, object]) -> dict[str, int]:
  facts_value: object = payload.get("facts")
  if not isinstance(facts_value, dict):
    return {
      "taxonomy_count": 0,
      "fact_count": 0,
      "unit_count": 0,
      "fact_entry_count": 0,
    }

  taxonomy_count: int = 0
  fact_count: int = 0
  unit_count: int = 0
  fact_entry_count: int = 0
  for taxonomy_value in facts_value.values():
    if not isinstance(taxonomy_value, dict):
      continue
    taxonomy_count += 1
    for fact_value in taxonomy_value.values():
      if not isinstance(fact_value, dict):
        continue
      units_value: object = fact_value.get("units")
      if not isinstance(units_value, dict):
        continue
      fact_count += 1
      unit_count += len(units_value)
      for unit_entries in units_value.values():
        if isinstance(unit_entries, list):
          fact_entry_count += len(unit_entries)

  return {
    "taxonomy_count": taxonomy_count,
    "fact_count": fact_count,
    "unit_count": unit_count,
    "fact_entry_count": fact_entry_count,
  }
