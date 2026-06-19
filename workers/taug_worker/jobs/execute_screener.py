from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from ..supabase_rest import SupabaseRestClient


@dataclass(frozen=True)
class ScreenerResult:
  company_id: str
  display_name: str
  primary_ticker: str | None
  metrics: dict[str, float | None]
  quality: dict[str, str | None]


@dataclass(frozen=True)
class ScreenerExecutionSummary:
  screener_id: str
  screener_name: str
  result_count: int
  results: tuple[ScreenerResult, ...]


_OPERATOR_MAP: dict[str, str] = {
  "eq": "eq",
  "neq": "neq",
  "gt": "gt",
  "gte": "gte",
  "lt": "lt",
  "lte": "lte",
}

_METRIC_COLUMNS: frozenset[str] = frozenset({
  "gross_margin",
  "operating_margin",
  "net_margin",
  "roe",
  "roa",
  "debt_equity",
  "current_ratio",
  "fcf",
  "fcf_margin",
  "ocf_to_net_income",
  "revenue_yoy",
  "eps_yoy",
  "pe",
  "pb",
  "ps",
  "ev_ebit",
  "ev_ebitda",
  "market_cap",
  "enterprise_value",
})

_QUALITY_COLUMNS: frozenset[str] = frozenset({
  "statement_freshness",
  "filing_coverage_status",
  "fact_coverage_status",
})

_ALL_VALID_COLUMNS: frozenset[str] = _METRIC_COLUMNS | _QUALITY_COLUMNS | frozenset({
  "company_id",
  "display_name",
  "primary_ticker",
  "security_id",
})


def run_execute_screener(
  *,
  supabase_client: SupabaseRestClient,
  screener_id: str,
) -> ScreenerExecutionSummary:
  screener = _load_screener(supabase_client, screener_id)

  filter_definition: list[dict[str, Any]] = screener.get("filter_definition", [])
  sort_definition: list[dict[str, Any]] = screener.get("sort_definition", [])
  universe_code: str = screener.get("universe_code", "all")
  limit: int = screener.get("metadata", {}).get("result_limit", 250)

  query = _build_query(
    filter_definition=filter_definition,
    sort_definition=sort_definition,
    universe_code=universe_code,
    limit=limit,
  )

  rows: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "screener_results_v",
    query=query,
  )

  results: list[ScreenerResult] = []
  for row in rows:
    metrics: dict[str, float | None] = {}
    for col in _METRIC_COLUMNS:
      metrics[col] = row.get(col)
    quality: dict[str, str | None] = {}
    for col in _QUALITY_COLUMNS:
      quality[col] = row.get(col)
    results.append(ScreenerResult(
      company_id=str(row.get("company_id", "")),
      display_name=str(row.get("display_name", "")),
      primary_ticker=row.get("primary_ticker"),
      metrics=metrics,
      quality=quality,
    ))

  _update_screener_run_status(
    supabase_client,
    screener_id=screener_id,
    result_count=len(results),
  )

  return ScreenerExecutionSummary(
    screener_id=screener_id,
    screener_name=str(screener.get("name", "")),
    result_count=len(results),
    results=tuple(results),
  )


def _load_screener(
  supabase_client: SupabaseRestClient,
  screener_id: str,
) -> dict[str, Any]:
  rows: list[dict[str, Any]] = supabase_client._request(
    "GET",
    "saved_screeners",
    query={
      "select": "*",
      "id": f"eq.{screener_id}",
      "limit": "1",
    },
  )
  if not rows:
    raise ValueError(f"Screener not found: {screener_id}")
  return rows[0]


def _build_query(
  *,
  filter_definition: list[dict[str, Any]],
  sort_definition: list[dict[str, Any]],
  universe_code: str,
  limit: int,
) -> dict[str, str]:
  query: dict[str, str] = {"select": "*"}

  if universe_code != "all":
    query["universe_code"] = f"eq.{universe_code}"

  for filt in filter_definition:
    metric_code: str | None = filt.get("metric_code")
    operator: str | None = filt.get("operator")
    value: object = filt.get("value")
    null_policy: str = filt.get("null_policy", "exclude")

    if not metric_code or not operator:
      continue
    if metric_code not in _ALL_VALID_COLUMNS:
      continue

    if operator == "is_null":
      query[metric_code] = "is.null"
      continue
    if operator == "is_not_null":
      query[metric_code] = "not.is.null"
      continue

    if value is None:
      continue

    pg_op = _OPERATOR_MAP.get(operator)
    if pg_op is None:
      continue

    query[metric_code] = f"{pg_op}.{value}"

  if sort_definition:
    order_parts: list[str] = []
    for sort in sort_definition:
      sort_metric: str | None = sort.get("metric_code")
      direction: str = sort.get("direction", "desc")
      if sort_metric and sort_metric in _ALL_VALID_COLUMNS:
        order_parts.append(f"{sort_metric}.{direction}")
    if order_parts:
      query["order"] = ",".join(order_parts)

  query["limit"] = str(min(limit, 500))

  return query


def _update_screener_run_status(
  supabase_client: SupabaseRestClient,
  *,
  screener_id: str,
  result_count: int,
) -> None:
  now = datetime.now(timezone.utc).isoformat()
  supabase_client._request(
    "PATCH",
    "saved_screeners",
    query={"id": f"eq.{screener_id}"},
    headers={
      "Prefer": "return=minimal",
    },
    payload={
      "last_run_at": now,
      "last_result_count": result_count,
      "updated_at": now,
    },
  )
