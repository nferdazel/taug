from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from hashlib import sha256
from typing import Any

from ..__init__ import __version__
from ..supabase_rest import (
  MetricDefinitionRecord,
  SupabaseRestClient,
  UpsertResult,
)


ANNUAL_MIN_DAYS: int = 250
HISTORY_FETCH_LIMIT: int = 40

TTM_INCOME_FACTS: frozenset[str] = frozenset({
  "revenue", "gross_profit", "operating_income", "net_income",
  "operating_cash_flow", "capex", "depreciation_amortization",
  "rd_expense", "sga_expense", "interest_income_net", "income_tax",
  "investing_cash_flow", "financing_cash_flow", "share_repurchases",
})

BALANCE_FACTS: frozenset[str] = frozenset({
  "total_assets", "total_liabilities", "stockholders_equity",
  "cash_and_equivalents", "current_assets", "current_liabilities",
  "long_term_debt", "retained_earnings",
})

EPS_FACTS: frozenset[str] = frozenset({
  "eps_basic", "eps_diluted",
})


@dataclass(frozen=True)
class StatementPeriod:
  period_end: str
  period_start: str | None
  published_at: str | None
  statement_type: str
  is_annual: bool
  revenue: float | None
  gross_profit: float | None
  operating_income: float | None
  net_income: float | None
  total_assets: float | None
  total_liabilities: float | None
  stockholders_equity: float | None
  cash_and_equivalents: float | None
  operating_cash_flow: float | None
  capex: float | None
  depreciation_amortization: float | None
  rd_expense: float | None
  sga_expense: float | None
  interest_income_net: float | None
  income_tax: float | None
  current_assets: float | None
  current_liabilities: float | None
  long_term_debt: float | None
  retained_earnings: float | None
  investing_cash_flow: float | None
  financing_cash_flow: float | None
  share_repurchases: float | None
  shares_outstanding: float | None
  eps_basic: float | None
  eps_diluted: float | None
  currency_code: str | None


@dataclass(frozen=True)
class TTMFigures:
  revenue: float | None
  gross_profit: float | None
  operating_income: float | None
  net_income: float | None
  operating_cash_flow: float | None
  capex: float | None
  depreciation_amortization: float | None
  eps_diluted: float | None
  period_end: str | None
  published_at: str | None
  source_type: str


@dataclass(frozen=True)
class MetricComputationResult:
  metric_code: str
  value_numeric: float | None
  computation_status: str
  stale_input_flag: bool
  missing_input_flag: bool
  validation_warning_flag: bool
  reporting_period_id: str | None
  as_of_date: str
  input_fingerprint: str


@dataclass(frozen=True)
class ComputeMetricsSummary:
  run_id: str
  processed_companies: int
  succeeded_companies: int
  failed_companies: int
  computed_snapshots: int
  skipped_snapshots: int
  successful_company_ids: tuple[str, ...]
  failed_company_ids: tuple[str, ...]


def run_compute_company_metrics(
  *,
  company_ids: list[str],
  supabase_client: SupabaseRestClient,
) -> ComputeMetricsSummary:
  if not company_ids:
    raise ValueError("At least one company_id is required")

  definitions: list[dict[str, Any]] = supabase_client.list_metric_definitions()
  defs_by_code: dict[str, dict[str, Any]] = {
    str(d["code"]): d for d in definitions if isinstance(d.get("code"), str)
  }
  definition_id_map: dict[str, str] = {
    code: str(d["id"]) for code, d in defs_by_code.items()
  }

  run_id: str = supabase_client.insert_metric_calculation_run(
    run_type="single_company" if len(company_ids) == 1 else "full_recompute",
    trigger_reason="manual",
    worker_version=__version__,
    metadata={"company_count": len(company_ids)},
  )

  success_count: int = 0
  failure_count: int = 0
  total_computed: int = 0
  total_skipped: int = 0
  successful_ids: list[str] = []
  failed_ids: list[str] = []

  try:
    for company_id in company_ids:
      try:
        security: Any = supabase_client.get_primary_security_for_company(
          company_id=company_id,
        )
        if security is None:
          failure_count += 1
          failed_ids.append(company_id)
          continue

        history_rows: list[dict[str, Any]] = (
          supabase_client.list_statement_history_for_company(
            company_id=company_id,
            limit=HISTORY_FETCH_LIMIT,
          )
        )
        if not history_rows:
          failure_count += 1
          failed_ids.append(company_id)
          continue

        periods: list[StatementPeriod] = _parse_statement_periods(history_rows)
        annual_rows: list[StatementPeriod] = [
          p for p in periods if p.is_annual
        ]
        quarterly_rows: list[StatementPeriod] = [
          p for p in periods if not p.is_annual
        ]

        latest_annual_income: StatementPeriod | None = _latest_annual_of_type(
          annual_rows, "income_statement"
        )
        latest_annual_cf: StatementPeriod | None = _latest_annual_of_type(
          annual_rows, "cash_flow"
        )
        latest_annual: StatementPeriod | None = (
          latest_annual_income or latest_annual_cf or (annual_rows[0] if annual_rows else None)
        )
        latest_quarterly: StatementPeriod | None = (
          quarterly_rows[0] if quarterly_rows else None
        )
        latest_balance: StatementPeriod | None = _latest_balance_sheet(periods)

        ttm_income: TTMFigures | None = _compute_ttm_income(
          annual_rows, quarterly_rows, periods
        )
        prior_ttm_income: TTMFigures | None = _compute_prior_ttm_income(
          annual_rows, quarterly_rows, periods
        )

        currency_code: str | None = (
          (latest_annual.currency_code if latest_annual else None)
          or (latest_quarterly.currency_code if latest_quarterly else None)
          or (periods[0].currency_code if periods else None)
        )

        as_of_date: str = (
          _extract_date(latest_annual.published_at or latest_annual.period_end)
          if latest_annual
          else _extract_date(
            latest_quarterly.published_at or latest_quarterly.period_end
          )
          if latest_quarterly
          else _today_iso()
        )

        computed: int = 0
        skipped: int = 0
        for code, defn in defs_by_code.items():
          definition_id: str = str(defn["id"])
          formula_version: str = str(defn.get("formula_version", "v1"))

          result: MetricComputationResult = _compute_metric(
            code=code,
            ttm=ttm_income,
            prior_ttm=prior_ttm_income,
            balance=latest_balance,
            latest_annual=latest_annual,
            as_of_date=as_of_date,
          )

          fp_input: str = f"{code}|{result.as_of_date}|{ttm_income.period_end if ttm_income else ''}"
          fingerprint: str = sha256(fp_input.encode("utf-8")).hexdigest()[:16]

          upsert_result: UpsertResult = (
            supabase_client.upsert_security_metric_snapshot(
              security_id=security.security_id,
              company_id=company_id,
              metric_definition_id=definition_id,
              reporting_period_id=result.reporting_period_id,
              as_of_date=result.as_of_date,
              value_numeric=result.value_numeric,
              computation_status=result.computation_status,
              stale_input_flag=result.stale_input_flag,
              missing_input_flag=result.missing_input_flag,
              validation_warning_flag=result.validation_warning_flag,
              currency_id=None,
              calculation_run_id=run_id,
              formula_version=formula_version,
              input_fingerprint=fingerprint,
              metadata={
                "source": "sec_edgar",
                "worker_version": __version__,
                "ttm_source": ttm_income.source_type if ttm_income else None,
              },
            )
          )
          if upsert_result.created:
            computed += 1
          else:
            skipped += 1

        total_computed += computed
        total_skipped += skipped
        successful_ids.append(company_id)
        success_count += 1
      except Exception as exc:
        failure_count += 1
        failed_ids.append(company_id)

    final_status: str = "success" if failure_count == 0 else "partial"
    supabase_client.update_metric_calculation_run(
      run_id=run_id,
      status=final_status,
      metadata={
        "processed_companies": len(company_ids),
        "succeeded_companies": success_count,
        "failed_companies": failure_count,
        "computed_snapshots": total_computed,
        "skipped_snapshots": total_skipped,
        "successful_company_ids": successful_ids,
        "failed_company_ids": failed_ids,
      },
    )
  except Exception as exc:
    supabase_client.update_metric_calculation_run(
      run_id=run_id,
      status="failed",
      metadata={
        "processed_companies": len(company_ids),
        "succeeded_companies": success_count,
        "failed_companies": failure_count,
        "computed_snapshots": total_computed,
        "skipped_snapshots": total_skipped,
      },
    )
    raise

  return ComputeMetricsSummary(
    run_id=run_id,
    processed_companies=len(company_ids),
    succeeded_companies=success_count,
    failed_companies=failure_count,
    computed_snapshots=total_computed,
    skipped_snapshots=total_skipped,
    successful_company_ids=tuple(successful_ids),
    failed_company_ids=tuple(failed_ids),
  )


def _parse_statement_periods(rows: list[dict[str, Any]]) -> list[StatementPeriod]:
  periods: list[StatementPeriod] = []
  for row in rows:
    period_end: str = str(row.get("period_end", ""))
    period_start_raw: str | None = (
      str(row["period_start"]) if row.get("period_start") else None
    )
    if not period_end:
      continue

    is_annual: bool = False
    if period_start_raw:
      try:
        start = datetime.fromisoformat(period_start_raw)
        end = datetime.fromisoformat(period_end)
        day_count: int = (end - start).days
        is_annual = day_count >= ANNUAL_MIN_DAYS
      except ValueError:
        pass

    periods.append(
      StatementPeriod(
        period_end=period_end,
        period_start=period_start_raw,
        published_at=str(row["published_at"]) if row.get("published_at") else None,
        statement_type=str(row.get("statement_type", "")),
        is_annual=is_annual,
        revenue=_num(row, "revenue"),
        gross_profit=_num(row, "gross_profit"),
        operating_income=_num(row, "operating_income"),
        net_income=_num(row, "net_income"),
        total_assets=_num(row, "total_assets"),
        total_liabilities=_num(row, "total_liabilities"),
        stockholders_equity=_num(row, "stockholders_equity"),
        cash_and_equivalents=_num(row, "cash_and_equivalents"),
        operating_cash_flow=_num(row, "operating_cash_flow"),
        capex=_num(row, "capex"),
        depreciation_amortization=_num(row, "depreciation_amortization"),
        rd_expense=_num(row, "rd_expense"),
        sga_expense=_num(row, "sga_expense"),
        interest_income_net=_num(row, "interest_income_net"),
        income_tax=_num(row, "income_tax"),
        current_assets=_num(row, "current_assets"),
        current_liabilities=_num(row, "current_liabilities"),
        long_term_debt=_num(row, "long_term_debt"),
        retained_earnings=_num(row, "retained_earnings"),
        investing_cash_flow=_num(row, "investing_cash_flow"),
        financing_cash_flow=_num(row, "financing_cash_flow"),
        share_repurchases=_num(row, "share_repurchases"),
        shares_outstanding=_num(row, "shares_outstanding"),
        eps_basic=_num(row, "eps_basic"),
        eps_diluted=_num(row, "eps_diluted"),
        currency_code=str(row["currency_code"]) if row.get("currency_code") else None,
      )
    )
  return periods


def _latest_balance_sheet(periods: list[StatementPeriod]) -> StatementPeriod | None:
  for p in periods:
    if p.statement_type == "balance_sheet":
      return p
  return None


def _latest_annual_of_type(
  annual_rows: list[StatementPeriod],
  statement_type: str,
) -> StatementPeriod | None:
  for p in annual_rows:
    if p.statement_type == statement_type:
      return p
  return None


def _num(row: dict[str, Any], key: str) -> float | None:
  val: Any = row.get(key)
  if isinstance(val, (int, float)):
    return float(val)
  return None


def _compute_ttm_income(
  annual_rows: list[StatementPeriod],
  quarterly_rows: list[StatementPeriod],
  all_periods: list[StatementPeriod],
) -> TTMFigures | None:
  annual_income = _latest_annual_of_type(annual_rows, "income_statement")
  annual_cf = _latest_annual_of_type(annual_rows, "cash_flow")

  if annual_income:
    return TTMFigures(
      revenue=annual_income.revenue,
      gross_profit=annual_income.gross_profit,
      operating_income=annual_income.operating_income,
      net_income=annual_income.net_income,
      operating_cash_flow=annual_cf.operating_cash_flow if annual_cf else None,
      capex=annual_cf.capex if annual_cf else None,
      depreciation_amortization=annual_cf.depreciation_amortization if annual_cf else None,
      eps_diluted=annual_income.eps_diluted,
      period_end=annual_income.period_end,
      published_at=annual_income.published_at,
      source_type="annual",
    )

  income_quarterly = [p for p in quarterly_rows if p.statement_type == "income_statement"]
  cf_quarterly = [p for p in quarterly_rows if p.statement_type == "cash_flow"]

  if len(income_quarterly) >= 4:
    q4 = income_quarterly[:4]
    cf_q4 = cf_quarterly[:4] if len(cf_quarterly) >= 4 else []
    return TTMFigures(
      revenue=_sum_or_none([q.revenue for q in q4]),
      gross_profit=_sum_or_none([q.gross_profit for q in q4]),
      operating_income=_sum_or_none([q.operating_income for q in q4]),
      net_income=_sum_or_none([q.net_income for q in q4]),
      operating_cash_flow=_sum_or_none([q.operating_cash_flow for q in cf_q4]) if cf_q4 else None,
      capex=_sum_or_none([q.capex for q in cf_q4]) if cf_q4 else None,
      depreciation_amortization=_sum_or_none([q.depreciation_amortization for q in cf_q4]) if cf_q4 else None,
      eps_diluted=_sum_or_none([q.eps_diluted for q in q4]),
      period_end=q4[0].period_end,
      published_at=q4[0].published_at,
      source_type="quarterly_sum",
    )

  return None


def _compute_prior_ttm_income(
  annual_rows: list[StatementPeriod],
  quarterly_rows: list[StatementPeriod],
  all_periods: list[StatementPeriod],
) -> TTMFigures | None:
  annual_income = _latest_annual_of_type(annual_rows, "income_statement")
  annual_cf = _latest_annual_of_type(annual_rows, "cash_flow")

  if len(annual_rows) >= 2:
    prev_income = None
    prev_cf = None
    for p in annual_rows:
      if p.statement_type == "income_statement" and p != annual_income:
        prev_income = p
        break
    for p in annual_rows:
      if p.statement_type == "cash_flow" and p != annual_cf:
        prev_cf = p
        break
    prev = prev_income or prev_cf
    if prev:
      return TTMFigures(
        revenue=prev_income.revenue if prev_income else None,
        gross_profit=prev_income.gross_profit if prev_income else None,
        operating_income=prev_income.operating_income if prev_income else None,
        net_income=prev_income.net_income if prev_income else None,
        operating_cash_flow=prev_cf.operating_cash_flow if prev_cf else None,
        capex=prev_cf.capex if prev_cf else None,
        depreciation_amortization=prev_cf.depreciation_amortization if prev_cf else None,
        eps_diluted=prev_income.eps_diluted if prev_income else None,
        period_end=prev.period_end,
        published_at=prev.published_at,
        source_type="annual",
      )

  income_quarterly = [p for p in quarterly_rows if p.statement_type == "income_statement"]
  cf_quarterly = [p for p in quarterly_rows if p.statement_type == "cash_flow"]

  if len(income_quarterly) >= 8:
    q8 = income_quarterly[4:8]
    cf_q8 = cf_quarterly[4:8] if len(cf_quarterly) >= 8 else []
    return TTMFigures(
      revenue=_sum_or_none([q.revenue for q in q8]),
      gross_profit=_sum_or_none([q.gross_profit for q in q8]),
      operating_income=_sum_or_none([q.operating_income for q in q8]),
      net_income=_sum_or_none([q.net_income for q in q8]),
      operating_cash_flow=_sum_or_none([q.operating_cash_flow for q in cf_q8]) if cf_q8 else None,
      capex=_sum_or_none([q.capex for q in cf_q8]) if cf_q8 else None,
      depreciation_amortization=_sum_or_none([q.depreciation_amortization for q in cf_q8]) if cf_q8 else None,
      eps_diluted=_sum_or_none([q.eps_diluted for q in q8]),
      period_end=q8[0].period_end,
      published_at=q8[0].published_at,
      source_type="quarterly_sum",
    )

  return None


def _compute_metric(
  *,
  code: str,
  ttm: TTMFigures | None,
  prior_ttm: TTMFigures | None,
  balance: StatementPeriod | None,
  latest_annual: StatementPeriod | None,
  as_of_date: str,
) -> MetricComputationResult:
  no_input = MetricComputationResult(
    metric_code=code,
    value_numeric=None,
    computation_status="missing_input",
    stale_input_flag=False,
    missing_input_flag=True,
    validation_warning_flag=False,
    reporting_period_id=None,
    as_of_date=as_of_date,
    input_fingerprint="",
  )

  if code in ("market_cap", "enterprise_value", "pe", "pb", "ps", "ev_ebit", "ev_ebitda"):
    return MetricComputationResult(
      metric_code=code,
      value_numeric=None,
      computation_status="missing_input",
      stale_input_flag=False,
      missing_input_flag=True,
      validation_warning_flag=False,
      reporting_period_id=None,
      as_of_date=as_of_date,
      input_fingerprint="needs_price_data",
    )

  if code == "gross_margin":
    val = _safe_div(ttm.gross_profit, ttm.revenue) if ttm else None
    return _ratio_result(code, val, ttm, as_of_date)

  if code == "operating_margin":
    val = _safe_div(ttm.operating_income, ttm.revenue) if ttm else None
    return _ratio_result(code, val, ttm, as_of_date)

  if code == "net_margin":
    val = _safe_div(ttm.net_income, ttm.revenue) if ttm else None
    return _ratio_result(code, val, ttm, as_of_date)

  if code == "roe":
    if ttm and ttm.net_income is not None and balance and balance.stockholders_equity is not None:
      val = _safe_div(ttm.net_income, balance.stockholders_equity)
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  if code == "roa":
    if ttm and ttm.net_income is not None and balance and balance.total_assets is not None:
      val = _safe_div(ttm.net_income, balance.total_assets)
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  if code == "debt_equity":
    if balance and balance.long_term_debt is not None and balance.stockholders_equity is not None:
      val = _safe_div(balance.long_term_debt, balance.stockholders_equity)
      return _balance_result(code, val, balance, as_of_date)
    return no_input

  if code == "current_ratio":
    if balance and balance.current_assets is not None and balance.current_liabilities is not None:
      val = _safe_div(balance.current_assets, balance.current_liabilities)
      return _balance_result(code, val, balance, as_of_date)
    return no_input

  if code == "fcf":
    if ttm and ttm.operating_cash_flow is not None and ttm.capex is not None:
      val = ttm.operating_cash_flow - abs(ttm.capex)
      return _monetary_result(code, val, ttm, as_of_date)
    return no_input

  if code == "fcf_margin":
    if (ttm and ttm.operating_cash_flow is not None and ttm.capex is not None
        and ttm.revenue is not None):
      fcf_val = ttm.operating_cash_flow - abs(ttm.capex)
      val = _safe_div(fcf_val, ttm.revenue)
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  if code == "ocf_to_net_income":
    if ttm and ttm.operating_cash_flow is not None and ttm.net_income is not None:
      val = _safe_div(ttm.operating_cash_flow, ttm.net_income)
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  if code == "revenue_yoy":
    if (ttm and ttm.revenue is not None
        and prior_ttm and prior_ttm.revenue is not None
        and prior_ttm.revenue != 0):
      val = (ttm.revenue / abs(prior_ttm.revenue)) - 1.0
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  if code == "eps_yoy":
    if (ttm and ttm.eps_diluted is not None
        and prior_ttm and prior_ttm.eps_diluted is not None
        and prior_ttm.eps_diluted != 0):
      val = (ttm.eps_diluted / abs(prior_ttm.eps_diluted)) - 1.0
      return _ratio_result(code, val, ttm, as_of_date)
    return no_input

  return no_input


def _ratio_result(
  code: str,
  val: float | None,
  ttm: TTMFigures | None,
  as_of_date: str,
) -> MetricComputationResult:
  if val is None:
    return MetricComputationResult(
      metric_code=code,
      value_numeric=None,
      computation_status="missing_input",
      stale_input_flag=False,
      missing_input_flag=True,
      validation_warning_flag=False,
      reporting_period_id=None,
      as_of_date=as_of_date,
      input_fingerprint="",
    )
  return MetricComputationResult(
    metric_code=code,
    value_numeric=val,
    computation_status="ok",
    stale_input_flag=False,
    missing_input_flag=False,
    validation_warning_flag=False,
    reporting_period_id=None,
    as_of_date=as_of_date,
    input_fingerprint=f"{ttm.period_end if ttm else ''}|{ttm.source_type if ttm else ''}",
  )


def _monetary_result(
  code: str,
  val: float | None,
  ttm: TTMFigures | None,
  as_of_date: str,
) -> MetricComputationResult:
  return _ratio_result(code, val, ttm, as_of_date)


def _balance_result(
  code: str,
  val: float | None,
  balance: StatementPeriod | None,
  as_of_date: str,
) -> MetricComputationResult:
  if val is None:
    return MetricComputationResult(
      metric_code=code,
      value_numeric=None,
      computation_status="missing_input",
      stale_input_flag=False,
      missing_input_flag=True,
      validation_warning_flag=False,
      reporting_period_id=None,
      as_of_date=as_of_date,
      input_fingerprint="",
    )
  return MetricComputationResult(
    metric_code=code,
    value_numeric=val,
    computation_status="ok",
    stale_input_flag=False,
    missing_input_flag=False,
    validation_warning_flag=False,
    reporting_period_id=None,
    as_of_date=as_of_date,
    input_fingerprint=f"balance|{balance.period_end if balance else ''}",
  )


def _safe_div(numerator: float | None, denominator: float | None) -> float | None:
  if numerator is None or denominator is None or denominator == 0:
    return None
  return numerator / denominator


def _sum_or_none(values: list[float | None]) -> float | None:
  present: list[float] = [v for v in values if v is not None]
  if not present:
    return None
  return sum(present)


def _extract_date(iso_timestamp: str | None) -> str:
  if not iso_timestamp:
    return _today_iso()
  try:
    return iso_timestamp[:10]
  except (IndexError, TypeError):
    return _today_iso()


def _today_iso() -> str:
  return datetime.now(timezone.utc).strftime("%Y-%m-%d")
