CREATE TABLE taug.saved_screeners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  universe_code TEXT NOT NULL DEFAULT 'all',
  filter_definition JSONB NOT NULL DEFAULT '[]'::jsonb,
  sort_definition JSONB NOT NULL DEFAULT '[]'::jsonb,
  selected_columns JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  last_run_at TIMESTAMPTZ,
  last_result_count INTEGER,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_saved_screeners_user
  ON taug.saved_screeners(user_id, is_default DESC);

ALTER TABLE taug.saved_screeners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own screeners"
  ON taug.saved_screeners FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.saved_screeners TO authenticated;

CREATE OR REPLACE VIEW taug.screener_results_v AS
WITH latest_metric_snapshots AS (
  SELECT DISTINCT ON (sms.security_id, md.code)
    sms.security_id,
    sms.company_id,
    md.code AS metric_code,
    sms.value_numeric,
    sms.computation_status,
    sms.as_of_date
  FROM taug.security_metric_snapshots AS sms
  JOIN taug.metric_definitions AS md ON md.id = sms.metric_definition_id
  WHERE sms.computation_status = 'ok'
  ORDER BY sms.security_id, md.code, sms.as_of_date DESC
),
pivoted_metrics AS (
  SELECT
    lms.company_id,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'gross_margin') AS gross_margin,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'operating_margin') AS operating_margin,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'net_margin') AS net_margin,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'roe') AS roe,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'roa') AS roa,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'debt_equity') AS debt_equity,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'current_ratio') AS current_ratio,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'fcf') AS fcf,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'fcf_margin') AS fcf_margin,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'ocf_to_net_income') AS ocf_to_net_income,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'revenue_yoy') AS revenue_yoy,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'eps_yoy') AS eps_yoy,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'pe') AS pe,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'pb') AS pb,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'ps') AS ps,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'ev_ebit') AS ev_ebit,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'ev_ebitda') AS ev_ebitda,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'market_cap') AS market_cap,
    MAX(lms.value_numeric) FILTER (WHERE lms.metric_code = 'enterprise_value') AS enterprise_value
  FROM latest_metric_snapshots AS lms
  GROUP BY lms.company_id
),
primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.id AS security_id,
    s.ticker,
    s.currency_code
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
),
quality_scores AS (
  SELECT
    company_id,
    statement_freshness,
    filing_coverage_status,
    fact_coverage_status
  FROM taug.company_data_quality_v
)
SELECT
  c.id AS company_id,
  c.display_name,
  ps.ticker AS primary_ticker,
  ps.security_id,
  pm.gross_margin,
  pm.operating_margin,
  pm.net_margin,
  pm.roe,
  pm.roa,
  pm.debt_equity,
  pm.current_ratio,
  pm.fcf,
  pm.fcf_margin,
  pm.ocf_to_net_income,
  pm.revenue_yoy,
  pm.eps_yoy,
  pm.pe,
  pm.pb,
  pm.ps,
  pm.ev_ebit,
  pm.ev_ebitda,
  pm.market_cap,
  pm.enterprise_value,
  qs.statement_freshness,
  qs.filing_coverage_status,
  qs.fact_coverage_status
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN pivoted_metrics AS pm
  ON pm.company_id = c.id
LEFT JOIN quality_scores AS qs
  ON qs.company_id = c.id;

GRANT SELECT ON taug.screener_results_v TO authenticated;
GRANT SELECT ON taug.screener_results_v TO service_role;
