from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from ..supabase_rest import SupabaseRestClient


@dataclass(frozen=True)
class QualityScoreResult:
  company_id: str
  overall_score: float
  historical_coverage_score: float
  completeness_score: float
  validation_score: float
  verification_score: float
  freshness_score: float
  restatement_support_score: float
  component_details: dict[str, object]


@dataclass(frozen=True)
class QualityComputeSummary:
  processed_companies: int
  succeeded_companies: int
  failed_companies: int
  successful_company_ids: tuple[str, ...]
  failed_company_ids: tuple[str, ...]


EXPECTED_FACTS_PER_PERIOD: int = 10
MAX_PERIODS_FOR_FULL_COVERAGE: int = 20


def run_compute_data_quality(
  *,
  supabase_client: SupabaseRestClient,
) -> QualityComputeSummary:
  companies: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "companies",
    query={"select": "id", "limit": "1000"},
  )
  if not companies:
    return QualityComputeSummary(
      processed_companies=0,
      succeeded_companies=0,
      failed_companies=0,
      successful_company_ids=(),
      failed_company_ids=(),
    )

  today: str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
  succeeded: list[str] = []
  failed: list[str] = []

  for company in companies:
    company_id: str = str(company["id"])
    try:
      result = _compute_company_quality(
        supabase_client=supabase_client,
        company_id=company_id,
        score_date=today,
      )
      _upsert_quality_score(
        supabase_client=supabase_client,
        company_id=company_id,
        result=result,
        score_date=today,
      )
      succeeded.append(company_id)
    except Exception:
      failed.append(company_id)

  return QualityComputeSummary(
    processed_companies=len(companies),
    succeeded_companies=len(succeeded),
    failed_companies=len(failed),
    successful_company_ids=tuple(succeeded),
    failed_company_ids=tuple(failed),
  )


def _compute_company_quality(
  *,
  supabase_client: SupabaseRestClient,
  company_id: str,
  score_date: str,
) -> QualityScoreResult:
  periods: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "reporting_periods",
    query={
      "select": "id,period_end,period_type",
      "company_id": f"eq.{company_id}",
      "order": "period_end.desc",
      "limit": "100",
    },
  )

  statements: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "financial_statements",
    query={
      "select": "id,reporting_period_id,statement_type,is_restated,supersedes_statement_id",
      "company_id": f"eq.{company_id}",
      "limit": "1000",
    },
  )

  statement_ids: list[str] = [str(s["id"]) for s in statements]
  item_count: int = 0
  if statement_ids:
    items: list[dict[str, Any]] = supabase_client._request(
      "GET",
      "financial_statement_items",
      query={
        "select": "id",
        "financial_statement_id": f"in.({','.join(statement_ids[:200])})",
        "limit": "5000",
      },
    )
    item_count = len(items)

  validation_events: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "validation_events",
    query={
      "select": "status",
      "entity_type": "eq.sec_company",
      "entity_id": f"eq.{company_id}",
      "limit": "500",
    },
  )

  restatement_count: int = sum(
    1 for s in statements if s.get("is_restated") is True
  )
  supersession_count: int = sum(
    1 for s in statements if s.get("supersedes_statement_id") is not None
  )

  period_count: int = len(periods)
  statement_count: int = len(statements)
  expected_items: int = period_count * EXPECTED_FACTS_PER_PERIOD

  historical_coverage: float = min(
    period_count / MAX_PERIODS_FOR_FULL_COVERAGE, 1.0
  )

  completeness: float = (
    min(item_count / expected_items, 1.0) if expected_items > 0 else 0.0
  )

  total_validations: int = len(validation_events)
  passed_validations: int = sum(
    1 for v in validation_events if v.get("status") == "passed"
  )
  validation: float = (
    passed_validations / total_validations if total_validations > 0 else 0.5
  )

  verification: float = 0.5
  if statements:
    has_verified: bool = any(
      s.get("last_verified_at") is not None for s in statements
    )
    verification = 1.0 if has_verified else 0.3

  freshness: float = 0.0
  if periods:
    latest_period: str = str(periods[0].get("period_end", ""))
    if latest_period:
      try:
        period_date = datetime.strptime(latest_period[:10], "%Y-%m-%d")
        days_since = (datetime.utcnow() - period_date).days
        if days_since <= 90:
          freshness = 1.0
        elif days_since <= 180:
          freshness = 0.8
        elif days_since <= 365:
          freshness = 0.6
        else:
          freshness = 0.3
      except ValueError:
        freshness = 0.0

  restatement_support: float = 1.0
  if restatement_count > 0 and supersession_count == 0:
    restatement_support = 0.5

  overall: float = (
    historical_coverage * 0.15
    + completeness * 0.25
    + validation * 0.20
    + verification * 0.10
    + freshness * 0.20
    + restatement_support * 0.10
  )

  return QualityScoreResult(
    company_id=company_id,
    overall_score=round(overall, 4),
    historical_coverage_score=round(historical_coverage, 4),
    completeness_score=round(completeness, 4),
    validation_score=round(validation, 4),
    verification_score=round(verification, 4),
    freshness_score=round(freshness, 4),
    restatement_support_score=round(restatement_support, 4),
    component_details={
      "period_count": period_count,
      "statement_count": statement_count,
      "item_count": item_count,
      "expected_items": expected_items,
      "total_validations": total_validations,
      "passed_validations": passed_validations,
      "restatement_count": restatement_count,
      "supersession_count": supersession_count,
    },
  )


def _upsert_quality_score(
  *,
  supabase_client: SupabaseRestClient,
  company_id: str,
  result: QualityScoreResult,
  score_date: str,
) -> None:
  existing: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "data_quality_scores",
    query={
      "select": "id",
      "company_id": f"eq.{company_id}",
      "score_date": f"eq.{score_date}",
      "limit": "1",
    },
  )

  payload: dict[str, object] = {
    "company_id": company_id,
    "score_date": score_date,
    "overall_score": result.overall_score,
    "historical_coverage_score": result.historical_coverage_score,
    "completeness_score": result.completeness_score,
    "validation_score": result.validation_score,
    "verification_score": result.verification_score,
    "freshness_score": result.freshness_score,
    "restatement_support_score": result.restatement_support_score,
    "component_details": result.component_details,
    "updated_at": datetime.now(timezone.utc).isoformat(),
  }

  if existing:
    supabase_client._request(
      "PATCH",
      "data_quality_scores",
      query={"id": f"eq.{existing[0]['id']}"},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )
  else:
    payload["created_at"] = datetime.now(timezone.utc).isoformat()
    supabase_client._request(
      "POST",
      "data_quality_scores",
      query={},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )
