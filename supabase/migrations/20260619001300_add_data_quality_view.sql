CREATE OR REPLACE VIEW taug.company_data_quality_v AS
WITH statement_freshness AS (
  SELECT
    fs.company_id,
    MAX(fs.published_at) AS latest_statement_published_at,
    MAX(fs.period_end) AS latest_statement_period_end,
    COUNT(*) AS total_statements,
    COUNT(*) FILTER (WHERE fs.is_restated) AS restated_statements
  FROM taug.financial_statements AS fs
  WHERE fs.status = 'active'
  GROUP BY fs.company_id
),
filing_coverage AS (
  SELECT
    f.company_id,
    COUNT(*) AS total_filings,
    COUNT(*) FILTER (WHERE f.filing_type IN ('10-K', '10-Q', '10-K/A', '10-Q/A')) AS annual_quarterly_filings,
    COUNT(*) FILTER (WHERE f.is_amendment) AS amendment_filings
  FROM taug.filings AS f
  GROUP BY f.company_id
),
validation_health AS (
  SELECT
    ve.entity_id,
    COUNT(*) FILTER (WHERE ve.status = 'passed') AS passed_validations,
    COUNT(*) FILTER (WHERE ve.status = 'failed') AS failed_validations
  FROM taug.validation_events AS ve
  WHERE ve.entity_type = 'raw_record'
  GROUP BY ve.entity_id
),
fact_coverage AS (
  SELECT
    c.id AS company_id,
    COUNT(fsi.id) AS total_items,
    COUNT(DISTINCT fs.statement_type) AS statement_types_covered
  FROM taug.companies AS c
  JOIN taug.financial_statements AS fs
    ON fs.company_id = c.id AND fs.status = 'active'
  JOIN taug.financial_statement_items AS fsi
    ON fsi.financial_statement_id = fs.id
  GROUP BY c.id
),
primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.id AS security_id,
    s.ticker
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
),
company_cik AS (
  SELECT
    si.security_id,
    si.identifier_value AS cik
  FROM taug.security_identifiers AS si
  WHERE si.identifier_type = 'CIK'
)
SELECT
  c.id AS company_id,
  c.display_name,
  ps.ticker AS primary_ticker,
  cc.cik,
  COALESCE(fc.total_filings, 0) AS total_filings,
  COALESCE(fc.annual_quarterly_filings, 0) AS annual_quarterly_filings,
  COALESCE(fc.amendment_filings, 0) AS amendment_filings,
  COALESCE(sf.total_statements, 0) AS total_statements,
  COALESCE(sf.restated_statements, 0) AS restated_statements,
  sf.latest_statement_published_at,
  sf.latest_statement_period_end,
  COALESCE(fcov.total_items, 0) AS total_fact_items,
  COALESCE(fcov.statement_types_covered, 0) AS statement_types_covered,
  COALESCE(vh.passed_validations, 0) AS passed_validations,
  COALESCE(vh.failed_validations, 0) AS failed_validations,
  CASE
    WHEN sf.latest_statement_published_at IS NULL THEN 'missing'
    WHEN sf.latest_statement_published_at >= NOW() - INTERVAL '120 days' THEN 'fresh'
    WHEN sf.latest_statement_published_at >= NOW() - INTERVAL '240 days' THEN 'stale'
    ELSE 'outdated'
  END AS statement_freshness,
  CASE
    WHEN COALESCE(fc.total_filings, 0) = 0 THEN 'no_filings'
    WHEN COALESCE(fc.annual_quarterly_filings, 0) >= 4 THEN 'good'
    WHEN COALESCE(fc.annual_quarterly_filings, 0) >= 1 THEN 'partial'
    ELSE 'minimal'
  END AS filing_coverage_status,
  CASE
    WHEN COALESCE(vh.failed_validations, 0) = 0 AND COALESCE(vh.passed_validations, 0) > 0 THEN 'healthy'
    WHEN COALESCE(vh.failed_validations, 0) = 0 THEN 'no_validations'
    WHEN vh.failed_validations::float / GREATEST(vh.passed_validations + vh.failed_validations, 1) < 0.1 THEN 'mostly_healthy'
    ELSE 'degraded'
  END AS validation_health_status,
  CASE
    WHEN COALESCE(fcov.total_items, 0) >= 50 THEN 'rich'
    WHEN COALESCE(fcov.total_items, 0) >= 10 THEN 'moderate'
    WHEN COALESCE(fcov.total_items, 0) > 0 THEN 'sparse'
    ELSE 'empty'
  END AS fact_coverage_status
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN company_cik AS cc
  ON cc.security_id = ps.security_id
LEFT JOIN filing_coverage AS fc
  ON fc.company_id = c.id
LEFT JOIN statement_freshness AS sf
  ON sf.company_id = c.id
LEFT JOIN fact_coverage AS fcov
  ON fcov.company_id = c.id
LEFT JOIN validation_health AS vh
  ON vh.entity_id = cc.cik;

GRANT SELECT ON taug.company_data_quality_v TO authenticated;
GRANT SELECT ON taug.company_data_quality_v TO service_role;
