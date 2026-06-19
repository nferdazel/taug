CREATE OR REPLACE VIEW taug.company_metric_snapshot_v AS
WITH latest_snapshots AS (
  SELECT DISTINCT ON (sms.security_id, sms.metric_definition_id)
    sms.id,
    sms.security_id,
    sms.company_id,
    sms.metric_definition_id,
    sms.reporting_period_id,
    sms.as_of_date,
    sms.value_numeric,
    sms.computation_status,
    sms.stale_input_flag,
    sms.missing_input_flag,
    sms.validation_warning_flag,
    sms.formula_version,
    sms.calculation_run_id,
    md.code AS metric_code,
    md.name AS metric_name,
    md.category AS metric_category,
    md.unit_type,
    md.display_precision,
    md.formula_expression
  FROM taug.security_metric_snapshots AS sms
  JOIN taug.metric_definitions AS md ON md.id = sms.metric_definition_id
  ORDER BY sms.security_id, sms.metric_definition_id, sms.as_of_date DESC
),
primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.id AS security_id,
    s.ticker
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
)
SELECT
  c.id AS company_id,
  c.display_name,
  ps.ticker AS primary_ticker,
  ls.metric_code,
  ls.metric_name,
  ls.metric_category,
  ls.value_numeric,
  ls.computation_status,
  ls.stale_input_flag,
  ls.missing_input_flag,
  ls.validation_warning_flag,
  ls.as_of_date,
  ls.formula_version,
  ls.formula_expression,
  ls.unit_type,
  ls.display_precision
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN latest_snapshots AS ls
  ON ls.company_id = c.id;

GRANT SELECT ON taug.company_metric_snapshot_v TO authenticated;
GRANT SELECT ON taug.company_metric_snapshot_v TO service_role;
