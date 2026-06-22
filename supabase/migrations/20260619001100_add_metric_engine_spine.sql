CREATE TABLE taug.metric_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  formula_expression TEXT NOT NULL,
  formula_version TEXT NOT NULL DEFAULT 'v1',
  unit_type TEXT NOT NULL,
  aggregation_mode TEXT NOT NULL DEFAULT 'latest',
  point_in_time_policy TEXT NOT NULL DEFAULT 'latest_available',
  staleness_policy TEXT NOT NULL DEFAULT 'allow_with_warning',
  display_precision SMALLINT NOT NULL DEFAULT 2,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (category IN ('valuation', 'profitability', 'leverage', 'cash_flow', 'scale', 'growth', 'other')),
  CHECK (unit_type IN ('monetary', 'ratio', 'percentage', 'shares', 'count')),
  CHECK (aggregation_mode IN ('reported_period', 'ttm', 'latest_balance_sheet', 'latest', 'average_two_period', 'price_as_of_date')),
  CHECK (point_in_time_policy IN ('filing_date_only', 'period_end_plus_filing_availability', 'latest_available', 'price_date_matched')),
  CHECK (staleness_policy IN ('strict_fail', 'allow_with_warning', 'allow_with_max_age'))
);

CREATE INDEX idx_metric_definitions_category
  ON taug.metric_definitions(category, is_active DESC);

ALTER TABLE taug.metric_definitions ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.metric_definitions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.metric_definitions TO service_role;

CREATE TABLE taug.metric_inputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_definition_id UUID NOT NULL REFERENCES taug.metric_definitions(id) ON DELETE CASCADE,
  input_kind TEXT NOT NULL,
  taxonomy_item_id UUID REFERENCES taug.statement_taxonomy_items(id) ON DELETE SET NULL,
  dependency_metric_definition_id UUID REFERENCES taug.metric_definitions(id) ON DELETE SET NULL,
  input_label TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (input_kind IN ('taxonomy_fact', 'metric_dependency', 'price_snapshot', 'computed'))
);

CREATE INDEX idx_metric_inputs_definition
  ON taug.metric_inputs(metric_definition_id);

ALTER TABLE taug.metric_inputs ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.metric_inputs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.metric_inputs TO service_role;

CREATE TABLE taug.metric_calculation_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_type TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'running',
  trigger_reason TEXT NOT NULL,
  trigger_reference_type TEXT,
  trigger_reference_id TEXT,
  worker_version TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('running', 'success', 'partial', 'failed')),
  CHECK (run_type IN ('full_recompute', 'incremental', 'single_company', 'single_metric'))
);

CREATE INDEX idx_metric_calculation_runs_status
  ON taug.metric_calculation_runs(status, started_at DESC);

ALTER TABLE taug.metric_calculation_runs ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.metric_calculation_runs TO service_role;

CREATE TABLE taug.security_metric_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  security_id UUID NOT NULL REFERENCES taug.securities(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  metric_definition_id UUID NOT NULL REFERENCES taug.metric_definitions(id) ON DELETE CASCADE,
  reporting_period_id UUID REFERENCES taug.reporting_periods(id) ON DELETE SET NULL,
  as_of_date DATE NOT NULL,
  value_numeric NUMERIC,
  computation_status TEXT NOT NULL DEFAULT 'ok',
  stale_input_flag BOOLEAN NOT NULL DEFAULT FALSE,
  missing_input_flag BOOLEAN NOT NULL DEFAULT FALSE,
  validation_warning_flag BOOLEAN NOT NULL DEFAULT FALSE,
  currency_id UUID REFERENCES taug.currencies(id) ON DELETE SET NULL,
  calculation_run_id UUID REFERENCES taug.metric_calculation_runs(id) ON DELETE SET NULL,
  formula_version TEXT NOT NULL,
  input_fingerprint TEXT,
  last_reported_at TIMESTAMPTZ,
  last_fetched_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (computation_status IN ('ok', 'missing_input', 'stale_input', 'validation_failed', 'not_applicable')),
  UNIQUE(security_id, metric_definition_id, reporting_period_id, as_of_date, formula_version)
);

CREATE INDEX idx_security_metric_snapshots_security_metric
  ON taug.security_metric_snapshots(security_id, metric_definition_id, as_of_date DESC);

CREATE INDEX idx_security_metric_snapshots_as_of
  ON taug.security_metric_snapshots(as_of_date DESC);

CREATE INDEX idx_security_metric_snapshots_company
  ON taug.security_metric_snapshots(company_id, metric_definition_id, as_of_date DESC);

ALTER TABLE taug.security_metric_snapshots ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.security_metric_snapshots TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.security_metric_snapshots TO service_role;

CREATE TABLE taug.security_price_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  security_id UUID NOT NULL REFERENCES taug.securities(id) ON DELETE CASCADE,
  price_date DATE NOT NULL,
  close_price NUMERIC(16,4),
  market_cap NUMERIC(20,2),
  enterprise_value NUMERIC(20,2),
  shares_outstanding NUMERIC(16,2),
  currency_id UUID REFERENCES taug.currencies(id) ON DELETE SET NULL,
  source_record_id UUID,
  last_fetched_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(security_id, price_date)
);

CREATE INDEX idx_security_price_snapshots_security_date
  ON taug.security_price_snapshots(security_id, price_date DESC);

ALTER TABLE taug.security_price_snapshots ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.security_price_snapshots TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.security_price_snapshots TO service_role;

CREATE TABLE taug.screening_universe_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  security_id UUID NOT NULL REFERENCES taug.securities(id) ON DELETE CASCADE,
  universe_code TEXT NOT NULL,
  effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to DATE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(security_id, universe_code, effective_from)
);

CREATE INDEX idx_screening_universe_security
  ON taug.screening_universe_memberships(security_id, universe_code);

CREATE INDEX idx_screening_universe_code_effective
  ON taug.screening_universe_memberships(universe_code, effective_from, effective_to);

ALTER TABLE taug.screening_universe_memberships ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.screening_universe_memberships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.screening_universe_memberships TO service_role;

INSERT INTO taug.metric_definitions (code, name, category, description, formula_expression, formula_version, unit_type, aggregation_mode, point_in_time_policy, staleness_policy, display_precision, is_active)
VALUES
  ('market_cap', 'Market Capitalization', 'scale', 'Market cap = share price * diluted shares outstanding', 'market_cap = close_price * shares_outstanding', 'v1', 'monetary', 'price_as_of_date', 'price_date_matched', 'allow_with_warning', 0, TRUE),
  ('enterprise_value', 'Enterprise Value', 'scale', 'EV = market cap + total debt - cash and equivalents', 'enterprise_value = market_cap + long_term_debt - cash_and_equivalents', 'v1', 'monetary', 'price_as_of_date', 'price_date_matched', 'allow_with_warning', 0, TRUE),
  ('pe', 'Price to Earnings', 'valuation', 'PE = market cap / TTM net income', 'pe = market_cap / ttm_net_income', 'v1', 'ratio', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('pb', 'Price to Book', 'valuation', 'PB = market cap / stockholders equity', 'pb = market_cap / stockholders_equity', 'v1', 'ratio', 'latest_balance_sheet', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('ps', 'Price to Sales', 'valuation', 'PS = market cap / TTM revenue', 'ps = market_cap / ttm_revenue', 'v1', 'ratio', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('ev_ebit', 'EV to EBIT', 'valuation', 'EV/EBIT = enterprise value / TTM EBIT', 'ev_ebit = enterprise_value / ttm_operating_income', 'v1', 'ratio', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('ev_ebitda', 'EV to EBITDA', 'valuation', 'EV/EBITDA = enterprise value / TTM EBITDA', 'ev_ebitda = enterprise_value / (ttm_operating_income + ttm_depreciation_amortization)', 'v1', 'ratio', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('gross_margin', 'Gross Margin', 'profitability', 'Gross margin = gross profit / revenue', 'gross_margin = gross_profit / revenue', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('operating_margin', 'Operating Margin', 'profitability', 'Operating margin = operating income / revenue', 'operating_margin = operating_income / revenue', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('net_margin', 'Net Margin', 'profitability', 'Net margin = net income / revenue', 'net_margin = net_income / revenue', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('roe', 'Return on Equity', 'profitability', 'ROE = net income / average stockholders equity', 'roe = ttm_net_income / avg_stockholders_equity', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('roa', 'Return on Assets', 'profitability', 'ROA = net income / average total assets', 'roa = ttm_net_income / avg_total_assets', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('debt_equity', 'Debt to Equity', 'leverage', 'Debt/equity = total debt / stockholders equity', 'debt_equity = long_term_debt / stockholders_equity', 'v1', 'ratio', 'latest_balance_sheet', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('current_ratio', 'Current Ratio', 'leverage', 'Current ratio = current assets / current liabilities', 'current_ratio = current_assets / current_liabilities', 'v1', 'ratio', 'latest_balance_sheet', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('fcf', 'Free Cash Flow', 'cash_flow', 'FCF = operating cash flow - capex', 'fcf = operating_cash_flow - abs(capex)', 'v1', 'monetary', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 0, TRUE),
  ('fcf_margin', 'FCF Margin', 'cash_flow', 'FCF margin = FCF / revenue', 'fcf_margin = fcf / ttm_revenue', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('ocf_to_net_income', 'OCF to Net Income', 'cash_flow', 'OCF/NI = operating cash flow / net income', 'ocf_to_net_income = operating_cash_flow / net_income', 'v1', 'ratio', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('revenue_yoy', 'Revenue YoY Growth', 'growth', 'Revenue YoY = current revenue / prior revenue - 1', 'revenue_yoy = ttm_revenue / prior_ttm_revenue - 1', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE),
  ('eps_yoy', 'EPS YoY Growth', 'growth', 'EPS YoY = current diluted EPS / prior diluted EPS - 1', 'eps_yoy = ttm_eps_diluted / prior_ttm_eps_diluted - 1', 'v1', 'percentage', 'ttm', 'period_end_plus_filing_availability', 'allow_with_warning', 2, TRUE);
