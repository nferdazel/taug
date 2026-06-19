from __future__ import annotations

from workers.taug_worker.jobs.compute_company_metrics import (
  TTMFigures,
  StatementPeriod,
  MetricComputationResult,
  _safe_div,
  _sum_or_none,
  _compute_metric,
  _extract_date,
  _today_iso,
)


def _make_ttm(
  *,
  revenue: float | None = 100.0,
  gross_profit: float | None = 45.0,
  operating_income: float | None = 30.0,
  net_income: float | None = 25.0,
  operating_cash_flow: float | None = 35.0,
  capex: float | None = -10.0,
  depreciation_amortization: float | None = 5.0,
  eps_diluted: float | None = 6.0,
) -> TTMFigures:
  return TTMFigures(
    revenue=revenue,
    gross_profit=gross_profit,
    operating_income=operating_income,
    net_income=net_income,
    operating_cash_flow=operating_cash_flow,
    capex=capex,
    depreciation_amortization=depreciation_amortization,
    eps_diluted=eps_diluted,
    period_end="2024-09-30",
    published_at="2024-10-30",
    source_type="quarterly_sum",
  )


def _make_balance(
  *,
  stockholders_equity: float | None = 50.0,
  total_assets: float | None = 350.0,
  long_term_debt: float | None = 100.0,
  current_assets: float | None = 150.0,
  current_liabilities: float | None = 120.0,
) -> StatementPeriod:
  return StatementPeriod(
    period_end="2024-09-30",
    period_start="2024-07-01",
    published_at="2024-10-30",
    statement_type="10-Q",
    is_annual=False,
    revenue=100.0,
    gross_profit=45.0,
    operating_income=30.0,
    net_income=25.0,
    total_assets=total_assets,
    total_liabilities=200.0,
    stockholders_equity=stockholders_equity,
    cash_and_equivalents=50.0,
    operating_cash_flow=35.0,
    capex=-10.0,
    depreciation_amortization=5.0,
    rd_expense=10.0,
    sga_expense=15.0,
    interest_income_net=2.0,
    income_tax=5.0,
    current_assets=current_assets,
    current_liabilities=current_liabilities,
    long_term_debt=long_term_debt,
    retained_earnings=100.0,
    investing_cash_flow=-20.0,
    financing_cash_flow=-5.0,
    share_repurchases=-10.0,
    shares_outstanding=15_000_000_000,
    eps_basic=6.5,
    eps_diluted=6.0,
    currency_code="USD",
  )


class TestSafeDiv:
  def test_normal_division(self) -> None:
    assert _safe_div(10.0, 2.0) == 5.0

  def test_zero_denominator_returns_none(self) -> None:
    assert _safe_div(10.0, 0.0) is None

  def test_none_numerator_returns_none(self) -> None:
    assert _safe_div(None, 2.0) is None

  def test_none_denominator_returns_none(self) -> None:
    assert _safe_div(10.0, None) is None

  def test_both_none_returns_none(self) -> None:
    assert _safe_div(None, None) is None


class TestSumOrNone:
  def test_sum_of_values(self) -> None:
    assert _sum_or_none([1.0, 2.0, 3.0]) == 6.0

  def test_sum_with_none(self) -> None:
    assert _sum_or_none([1.0, None, 3.0]) == 4.0

  def test_all_none_returns_none(self) -> None:
    assert _sum_or_none([None, None]) is None

  def test_empty_list_returns_none(self) -> None:
    assert _sum_or_none([]) is None


class TestComputeMetric:
  AS_OF = "2024-10-30"

  def test_gross_margin_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="gross_margin", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert result.value_numeric is not None
    assert abs(result.value_numeric - 0.45) < 0.01

  def test_operating_margin_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="operating_margin", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.30) < 0.01

  def test_net_margin_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="net_margin", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.25) < 0.01

  def test_roe_ok(self) -> None:
    ttm = _make_ttm()
    balance = _make_balance()
    result = _compute_metric(
      code="roe", ttm=ttm, prior_ttm=None,
      balance=balance, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.50) < 0.01

  def test_roe_missing_balance(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="roe", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "missing_input"

  def test_roa_ok(self) -> None:
    ttm = _make_ttm()
    balance = _make_balance()
    result = _compute_metric(
      code="roa", ttm=ttm, prior_ttm=None,
      balance=balance, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - (25.0 / 350.0)) < 0.01

  def test_debt_equity_ok(self) -> None:
    balance = _make_balance()
    result = _compute_metric(
      code="debt_equity", ttm=None, prior_ttm=None,
      balance=balance, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 2.0) < 0.01

  def test_current_ratio_ok(self) -> None:
    balance = _make_balance()
    result = _compute_metric(
      code="current_ratio", ttm=None, prior_ttm=None,
      balance=balance, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 1.25) < 0.01

  def test_fcf_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="fcf", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 25.0) < 0.01

  def test_fcf_margin_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="fcf_margin", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.25) < 0.01

  def test_ocf_to_net_income_ok(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="ocf_to_net_income", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - (35.0 / 25.0)) < 0.01

  def test_price_dependent_returns_missing_input(self) -> None:
    ttm = _make_ttm()
    for code in ("market_cap", "enterprise_value", "pe", "pb", "ps", "ev_ebit", "ev_ebitda"):
      result = _compute_metric(
        code=code, ttm=ttm, prior_ttm=None,
        balance=None, latest_annual=None, as_of_date=self.AS_OF,
      )
      assert result.computation_status == "missing_input", f"{code} should be missing_input"
      assert result.input_fingerprint == "needs_price_data"

  def test_revenue_yoy_ok(self) -> None:
    ttm = _make_ttm(revenue=120.0)
    prior = _make_ttm(revenue=100.0)
    result = _compute_metric(
      code="revenue_yoy", ttm=ttm, prior_ttm=prior,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.20) < 0.01

  def test_revenue_yoy_missing_prior(self) -> None:
    ttm = _make_ttm()
    result = _compute_metric(
      code="revenue_yoy", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "missing_input"

  def test_eps_yoy_ok(self) -> None:
    ttm = _make_ttm(eps_diluted=7.0)
    prior = _make_ttm(eps_diluted=5.0)
    result = _compute_metric(
      code="eps_yoy", ttm=ttm, prior_ttm=prior,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "ok"
    assert abs(result.value_numeric - 0.40) < 0.01

  def test_unknown_metric_returns_missing_input(self) -> None:
    result = _compute_metric(
      code="nonexistent_metric", ttm=None, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "missing_input"

  def test_gross_margin_with_none_revenue(self) -> None:
    ttm = _make_ttm(revenue=None)
    result = _compute_metric(
      code="gross_margin", ttm=ttm, prior_ttm=None,
      balance=None, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "missing_input"

  def test_debt_equity_with_zero_equity(self) -> None:
    balance = _make_balance(stockholders_equity=0.0)
    result = _compute_metric(
      code="debt_equity", ttm=None, prior_ttm=None,
      balance=balance, latest_annual=None, as_of_date=self.AS_OF,
    )
    assert result.computation_status == "missing_input"


class TestExtractDate:
  def test_iso_timestamp(self) -> None:
    assert _extract_date("2024-10-30T10:00:00Z") == "2024-10-30"

  def test_none_returns_today(self) -> None:
    assert _extract_date(None) == _today_iso()

  def test_empty_returns_today(self) -> None:
    assert _extract_date("") == _today_iso()

  def test_date_only(self) -> None:
    assert _extract_date("2024-10-30") == "2024-10-30"
