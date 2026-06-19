from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Iterable

from ..__init__ import __version__
from ..supabase_rest import (
  CanonicalSecurity,
  FilingRecord,
  FilingVersionRecord,
  RawSource,
  SupabaseRestClient,
  UpsertResult,
)
from ..validators.sec_companyfacts import (
  ValidationFailure,
  validate_sec_companyfacts_payload,
)


ALLOWED_FORMS: frozenset[str] = frozenset({"10-K", "10-Q", "10-K/A", "10-Q/A"})
STATEMENT_TYPE_INCOME: str = "income_statement"
STATEMENT_TYPE_BALANCE: str = "balance_sheet"
STATEMENT_TYPE_CASH_FLOW: str = "cash_flow"
STATEMENT_TYPE_EQUITY: str = "equity"


@dataclass(frozen=True)
class FactMapping:
  statement_type: str
  unit_type: str | None


FACT_CATALOG: dict[str, FactMapping] = {
  "RevenueFromContractWithCustomerExcludingAssessedTax": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "SalesRevenueNet": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "Revenues": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "GrossProfit": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "OperatingIncomeLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "NetIncomeLoss": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="monetary",
  ),
  "EarningsPerShareBasic": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="ratio",
  ),
  "EarningsPerShareDiluted": FactMapping(
    statement_type=STATEMENT_TYPE_INCOME,
    unit_type="ratio",
  ),
  "WeightedAverageNumberOfSharesOutstandingBasic": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "WeightedAverageNumberOfDilutedSharesOutstanding": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
  "Assets": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "AssetsCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CashAndCashEquivalentsAtCarryingValue": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "CashCashEquivalentsAndShortTermInvestments": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "Liabilities": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LiabilitiesCurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "StockholdersEquity": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermDebtNoncurrent": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "LongTermDebt": FactMapping(
    statement_type=STATEMENT_TYPE_BALANCE,
    unit_type="monetary",
  ),
  "NetCashProvidedByUsedInOperatingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToAcquirePropertyPlantAndEquipment": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "DepreciationDepletionAndAmortization": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "NetCashProvidedByUsedInInvestingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "NetCashProvidedByUsedInFinancingActivities": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "PaymentsToRepurchaseCommonStock": FactMapping(
    statement_type=STATEMENT_TYPE_CASH_FLOW,
    unit_type="monetary",
  ),
  "EntityCommonStockSharesOutstanding": FactMapping(
    statement_type=STATEMENT_TYPE_EQUITY,
    unit_type="shares",
  ),
}


@dataclass(frozen=True)
class ParseCompanyfactsSummary:
  fetch_run_id: str
  processed_ciks: int
  succeeded_ciks: int
  failed_ciks: int
  created_reporting_periods: int
  replayed_reporting_periods: int
  created_statements: int
  replayed_statements: int
  created_items: int
  replayed_items: int


def run_parse_sec_companyfacts(
  *,
  ciks: Iterable[str],
  supabase_client: SupabaseRestClient,
) -> ParseCompanyfactsSummary:
  normalized_ciks: list[str] = [cik.zfill(10) for cik in ciks if cik.strip()]
  if not normalized_ciks:
    raise ValueError("At least one CIK is required for parse_sec_companyfacts")

  source: RawSource = supabase_client.ensure_sec_source()
  checkpoint_scope: dict[str, object] = {
    "ciks": normalized_ciks,
    "job_type": "statement_parse",
    "record_type": "sec_companyfacts",
  }
  checkpoint_scope_key: str = supabase_client.build_checkpoint_scope_key(
    job_type="statement_parse",
    scope=checkpoint_scope,
  )
  fetch_run_id: str = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="statement_parse",
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
  created_reporting_periods: int = 0
  replayed_reporting_periods: int = 0
  created_statements: int = 0
  replayed_statements: int = 0
  created_items: int = 0
  replayed_items: int = 0
  successful_cik_ids: list[str] = []
  failed_cik_ids: list[str] = []
  currencies_by_code: dict[str, str] = supabase_client.list_currencies()

  try:
    raw_records = supabase_client.list_latest_raw_records(
      record_type="sec_companyfacts",
      source_entity_keys=normalized_ciks,
      limit=max(len(normalized_ciks) * 5, 10),
    )
    raw_records_by_cik: dict[str, Any] = {
      raw_record.source_entity_key: raw_record
      for raw_record in raw_records
      if raw_record.source_entity_key is not None
    }

    for cik in normalized_ciks:
      raw_record = raw_records_by_cik.get(cik)
      if raw_record is None:
        failure_count += 1
        failed_cik_ids.append(cik)
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule="sec_companyfacts_raw_record_available",
          status="failed",
          message="No latest sec_companyfacts raw_record was available for parsing.",
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
          },
        )
        continue

      try:
        payload_validation_failures: tuple[ValidationFailure, ...] = (
          validate_sec_companyfacts_payload(raw_record.payload_json)
        )
        if payload_validation_failures:
          raise ValueError(
            "SEC companyfacts payload validation failed during parse: "
            + ", ".join(failure.code for failure in payload_validation_failures)
          )

        canonical_security: CanonicalSecurity | None = (
          supabase_client.get_canonical_security_by_cik(cik=cik)
        )
        if canonical_security is None:
          entity_name: str = str(raw_record.metadata.get("entity_name") or cik)
          ticker_value: object = raw_record.metadata.get("ticker")
          ticker: str | None = ticker_value if isinstance(ticker_value, str) else None
          canonical_security = supabase_client.ensure_canonical_security(
            cik=cik,
            ticker=ticker,
            company_name=entity_name,
          )

        company_filings: list[FilingRecord] = supabase_client.list_filings_for_company(
          company_id=canonical_security.company_id,
          raw_source_id=source.id,
          limit=500,
        )
        filings_by_key: dict[str, FilingRecord] = {
          filing.filing_key: filing for filing in company_filings
        }
        active_versions_by_filing_id: dict[str, FilingVersionRecord] = {}
        for filing in company_filings:
          active_version = supabase_client.get_active_filing_version_by_filing(
            filing_id=filing.id,
          )
          if active_version is not None:
            active_versions_by_filing_id[filing.id] = active_version

        parse_counts = _parse_companyfacts_record(
          raw_record_id=raw_record.id,
          cik=cik,
          payload=raw_record.payload_json,
          company_id=canonical_security.company_id,
          security_id=canonical_security.security_id,
          filings_by_key=filings_by_key,
          active_versions_by_filing_id=active_versions_by_filing_id,
          currencies_by_code=currencies_by_code,
          supabase_client=supabase_client,
        )
        created_reporting_periods += parse_counts["created_reporting_periods"]
        replayed_reporting_periods += parse_counts["replayed_reporting_periods"]
        created_statements += parse_counts["created_statements"]
        replayed_statements += parse_counts["replayed_statements"]
        created_items += parse_counts["created_items"]
        replayed_items += parse_counts["replayed_items"]

        supabase_client.insert_validation_event(
          entity_type="raw_record",
          entity_id=raw_record.id,
          validation_rule="sec_companyfacts_statement_parse",
          status="passed",
          message="SEC companyfacts raw_record parsed into statement-layer rows.",
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            **parse_counts,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_statement_parsed",
          entity_type="raw_record",
          entity_id=raw_record.id,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "company_id": canonical_security.company_id,
            "security_id": canonical_security.security_id,
            **parse_counts,
          },
        )
        success_count += 1
        successful_cik_ids.append(cik)
      except Exception as exc:
        failure_count += 1
        failed_cik_ids.append(cik)
        supabase_client.insert_validation_event(
          entity_type="sec_company",
          entity_id=cik,
          validation_rule="sec_companyfacts_statement_parse",
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "raw_record_id": raw_record.id,
            "error_type": type(exc).__name__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="sec_companyfacts_statement_parse_failed",
          entity_type="sec_company",
          entity_id=cik,
          severity="error",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "worker_version": __version__,
            "cik": cik,
            "raw_record_id": raw_record.id,
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
      error_code = "sec_companyfacts_statement_parse_failed"
      error_message = "All requested CIKs failed during SEC companyfacts statement parsing."
    elif failure_count > 0:
      run_status = "partial"
      error_code = "sec_companyfacts_statement_parse_partial_failure"
      error_message = "One or more requested CIKs failed during SEC companyfacts statement parsing."

    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status=run_status,
      error_code=error_code,
      error_message=error_message,
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_reporting_periods": created_reporting_periods,
        "replayed_reporting_periods": replayed_reporting_periods,
        "created_statements": created_statements,
        "replayed_statements": replayed_statements,
        "created_items": created_items,
        "replayed_items": replayed_items,
      },
    )
    if success_count > 0:
      supabase_client.upsert_ingestion_checkpoint(
        raw_source_id=source.id,
        job_type="statement_parse",
        checkpoint_scope_key=checkpoint_scope_key,
        last_success_fetch_run_id=fetch_run_id,
        checkpoint_data={
          "successful_cik_ids": successful_cik_ids,
          "failed_cik_ids": failed_cik_ids,
          "created_reporting_periods": created_reporting_periods,
          "replayed_reporting_periods": replayed_reporting_periods,
          "created_statements": created_statements,
          "replayed_statements": replayed_statements,
          "created_items": created_items,
          "replayed_items": replayed_items,
        },
      )

    return ParseCompanyfactsSummary(
      fetch_run_id=fetch_run_id,
      processed_ciks=len(normalized_ciks),
      succeeded_ciks=success_count,
      failed_ciks=failure_count,
      created_reporting_periods=created_reporting_periods,
      replayed_reporting_periods=replayed_reporting_periods,
      created_statements=created_statements,
      replayed_statements=replayed_statements,
      created_items=created_items,
      replayed_items=replayed_items,
    )
  except Exception as exc:
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="failed",
      error_code="sec_companyfacts_statement_parse_failed",
      error_message=str(exc),
      metadata={
        "successful_cik_ids": successful_cik_ids,
        "failed_cik_ids": failed_cik_ids,
        "created_reporting_periods": created_reporting_periods,
        "replayed_reporting_periods": replayed_reporting_periods,
        "created_statements": created_statements,
        "replayed_statements": replayed_statements,
        "created_items": created_items,
        "replayed_items": replayed_items,
      },
    )
    raise


def _parse_companyfacts_record(
  *,
  raw_record_id: str,
  cik: str,
  payload: dict[str, object],
  company_id: str,
  security_id: str,
  filings_by_key: dict[str, FilingRecord],
  active_versions_by_filing_id: dict[str, FilingVersionRecord],
  currencies_by_code: dict[str, str],
  supabase_client: SupabaseRestClient,
) -> dict[str, int]:
  counts: dict[str, int] = {
    "created_reporting_periods": 0,
    "replayed_reporting_periods": 0,
    "created_statements": 0,
    "replayed_statements": 0,
    "created_items": 0,
    "replayed_items": 0,
    "matched_filings": 0,
    "skipped_entries": 0,
  }
  reporting_period_cache: dict[str, str] = {}
  statement_cache: dict[str, str] = {}
  taxonomy_cache: dict[str, str] = {}
  matched_filing_ids: set[str] = set()

  facts_value: object = payload.get("facts")
  if not isinstance(facts_value, dict):
    return counts

  for taxonomy_source, taxonomy_value in facts_value.items():
    if not isinstance(taxonomy_source, str) or not isinstance(taxonomy_value, dict):
      continue
    for concept_code, concept_payload in taxonomy_value.items():
      mapping: FactMapping | None = FACT_CATALOG.get(concept_code)
      if mapping is None:
        continue
      if not isinstance(concept_payload, dict):
        continue
      label_value: object = concept_payload.get("label")
      concept_label: str = (
        label_value.strip()
        if isinstance(label_value, str) and label_value.strip()
        else concept_code
      )
      taxonomy_key: str = f"{taxonomy_source}:{concept_code}"
      taxonomy_item_id: str | None = taxonomy_cache.get(taxonomy_key)
      if taxonomy_item_id is None:
        taxonomy_result: UpsertResult = supabase_client.upsert_statement_taxonomy_item(
          code=concept_code,
          name=concept_label,
          statement_type=mapping.statement_type,
          unit_type=mapping.unit_type,
          sign_convention="natural",
          taxonomy_source=taxonomy_source,
          is_core=True,
          metadata={
            "source": "sec_edgar",
            "parser": "sec_companyfacts",
            "cik": cik,
          },
        )
        taxonomy_item_id = taxonomy_result.id
        taxonomy_cache[taxonomy_key] = taxonomy_item_id

      units_value: object = concept_payload.get("units")
      if not isinstance(units_value, dict):
        continue
      for unit_name, fact_entries in units_value.items():
        if not isinstance(unit_name, str) or not isinstance(fact_entries, list):
          continue
        currency_id: str | None = _resolve_currency_id(
          unit=unit_name,
          currencies_by_code=currencies_by_code,
        )
        for entry in fact_entries:
          if not isinstance(entry, dict):
            counts["skipped_entries"] += 1
            continue
          parsed_entry = _parse_fact_entry(entry)
          if parsed_entry is None:
            counts["skipped_entries"] += 1
            continue
          accession_number: str = parsed_entry["accession_number"]
          filing_record: FilingRecord | None = filings_by_key.get(accession_number)
          if filing_record is None:
            counts["skipped_entries"] += 1
            continue
          active_version: FilingVersionRecord | None = active_versions_by_filing_id.get(
            filing_record.id
          )
          if active_version is None:
            counts["skipped_entries"] += 1
            continue
          matched_filing_ids.add(filing_record.id)

          reporting_period_cache_key: str = (
            f"{parsed_entry['period_type']}|{parsed_entry['fiscal_year']}|"
            f"{parsed_entry['fiscal_quarter']}|{parsed_entry['period_end']}"
          )
          reporting_period_id: str | None = reporting_period_cache.get(
            reporting_period_cache_key
          )
          if reporting_period_id is None:
            reporting_period_result: UpsertResult = supabase_client.upsert_reporting_period(
              company_id=company_id,
              period_type=parsed_entry["period_type"],
              fiscal_year=parsed_entry["fiscal_year"],
              fiscal_quarter=parsed_entry["fiscal_quarter"],
              period_start=parsed_entry["period_start"],
              period_end=parsed_entry["period_end"],
              label=parsed_entry["label"],
              last_reported_at=parsed_entry["filed_at"],
              last_fetched_at=_iso_now(),
              last_verified_at=_iso_now(),
              metadata={
                "source": "sec_edgar",
                "parser": "sec_companyfacts",
                "form": parsed_entry["form"],
                "accession_number": accession_number,
              },
            )
            reporting_period_id = reporting_period_result.id
            reporting_period_cache[reporting_period_cache_key] = reporting_period_id
            counts[
              "created_reporting_periods"
              if reporting_period_result.created
              else "replayed_reporting_periods"
            ] += 1

          statement_cache_key: str = (
            f"{active_version.id}|{mapping.statement_type}|{parsed_entry['period_end']}"
          )
          financial_statement_id: str | None = statement_cache.get(statement_cache_key)
          if financial_statement_id is None:
            statement_result: UpsertResult = supabase_client.upsert_financial_statement(
              company_id=company_id,
              security_id=security_id,
              filing_id=filing_record.id,
              filing_version_id=active_version.id,
              reporting_period_id=reporting_period_id,
              statement_type=mapping.statement_type,
              statement_version=1,
              currency_id=currency_id,
              period_start=parsed_entry["period_start"],
              period_end=parsed_entry["period_end"],
              published_at=parsed_entry["filed_at"],
              is_restated=filing_record.is_amendment,
              last_reported_at=parsed_entry["filed_at"],
              last_fetched_at=_iso_now(),
              last_verified_at=_iso_now(),
              parser_version=__version__,
              status="active",
              metadata={
                "source": "sec_edgar",
                "parser": "sec_companyfacts",
                "form": parsed_entry["form"],
                "accession_number": accession_number,
              },
            )
            financial_statement_id = statement_result.id
            statement_cache[statement_cache_key] = financial_statement_id
            counts[
              "created_statements"
              if statement_result.created
              else "replayed_statements"
            ] += 1

          lineage_source_id: str = "|".join(
            (
              raw_record_id,
              taxonomy_source,
              concept_code,
              unit_name,
              accession_number,
              parsed_entry["filed"],
              parsed_entry["period_start"] or "",
              parsed_entry["period_end"],
              parsed_entry["fp"] or "",
            )
          )
          item_result: UpsertResult = supabase_client.upsert_financial_statement_item(
            financial_statement_id=financial_statement_id,
            taxonomy_item_id=taxonomy_item_id,
            lineage_source_type="xbrl_fact",
            lineage_source_id=lineage_source_id,
            value_numeric=parsed_entry["value_numeric"],
            value_text=None,
            unit=unit_name,
            scale=_parse_optional_int(entry.get("scale")),
            decimals=_parse_optional_int(entry.get("decimals")),
            fact_period_start=parsed_entry["period_start"],
            fact_period_end=(
              parsed_entry["period_end"]
              if parsed_entry["period_type"] != "instant"
              else None
            ),
            fact_instant=(
              parsed_entry["period_end"]
              if parsed_entry["period_type"] == "instant"
              else None
            ),
            is_reported=True,
            is_calculated=False,
            confidence_score=1.0,
            metadata={
              "source": "sec_edgar",
              "parser": "sec_companyfacts",
              "form": parsed_entry["form"],
              "accession_number": accession_number,
              "filed": parsed_entry["filed"],
            },
          )
          counts["created_items" if item_result.created else "replayed_items"] += 1

  counts["matched_filings"] = len(matched_filing_ids)
  return counts


def _parse_fact_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
  form_value: object = entry.get("form")
  accession_value: object = entry.get("accn")
  end_value: object = entry.get("end")
  filed_value: object = entry.get("filed")
  value: object = entry.get("val")
  fiscal_year_value: object = entry.get("fy")
  fp_value: object = entry.get("fp")

  if (
    not isinstance(form_value, str)
    or form_value not in ALLOWED_FORMS
    or not isinstance(accession_value, str)
    or not isinstance(end_value, str)
    or not isinstance(filed_value, str)
    or not isinstance(fiscal_year_value, int)
    or not isinstance(value, (int, float))
  ):
    return None

  fp: str | None = fp_value if isinstance(fp_value, str) and fp_value.strip() else None
  period_start_value: object = entry.get("start")
  period_start: str | None = (
    period_start_value if isinstance(period_start_value, str) and period_start_value else None
  )
  period_type: str = _derive_period_type(form=form_value, fp=fp, period_start=period_start)
  fiscal_quarter: int | None = _derive_fiscal_quarter(fp=fp, period_type=period_type)
  label: str = _build_period_label(
    period_type=period_type,
    fiscal_year=fiscal_year_value,
    fiscal_quarter=fiscal_quarter,
    period_end=end_value,
  )

  return {
    "form": form_value,
    "accession_number": accession_value,
    "period_end": end_value,
    "period_start": period_start,
    "filed": filed_value,
    "filed_at": _date_to_timestamp(filed_value),
    "value_numeric": value,
    "fiscal_year": fiscal_year_value,
    "fiscal_quarter": fiscal_quarter,
    "period_type": period_type,
    "label": label,
    "fp": fp,
  }


def _derive_period_type(*, form: str, fp: str | None, period_start: str | None) -> str:
  if period_start is None:
    return "instant"
  if fp == "FY" or form in {"10-K", "10-K/A"}:
    return "annual"
  if fp in {"Q1", "Q2", "Q3"} or form in {"10-Q", "10-Q/A"}:
    return "quarterly"
  return "annual"


def _derive_fiscal_quarter(*, fp: str | None, period_type: str) -> int | None:
  if period_type != "quarterly":
    return None
  quarter_map: dict[str, int] = {"Q1": 1, "Q2": 2, "Q3": 3, "Q4": 4}
  if fp is None:
    return None
  return quarter_map.get(fp)


def _build_period_label(
  *,
  period_type: str,
  fiscal_year: int,
  fiscal_quarter: int | None,
  period_end: str,
) -> str:
  if period_type == "quarterly" and fiscal_quarter is not None:
    return f"Q{fiscal_quarter} FY{fiscal_year}"
  if period_type == "annual":
    return f"FY{fiscal_year}"
  return f"Instant {period_end}"


def _resolve_currency_id(
  *,
  unit: str,
  currencies_by_code: dict[str, str],
) -> str | None:
  unit_prefix: str = unit.split("/", 1)[0].upper()
  return currencies_by_code.get(unit_prefix)


def _parse_optional_int(value: object) -> int | None:
  if isinstance(value, int):
    return value
  if isinstance(value, str) and value.lstrip("-").isdigit():
    return int(value)
  return None


def _date_to_timestamp(value: str) -> str:
  return f"{value}T00:00:00+00:00"


def _iso_now() -> str:
  return datetime.now(timezone.utc).isoformat()
