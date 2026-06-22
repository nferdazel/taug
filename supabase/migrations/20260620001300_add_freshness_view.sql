-- Freshness Framework: Company Freshness View
--
-- Provides a unified freshness dashboard per company.
-- Combines freshness data from filings, statements, metrics, and prices.
--
-- Freshness scoring:
--   fresh:  < 30 days since latest data
--   aging:  30-90 days
--   stale:  90-365 days
--   expired: > 365 days
--   unknown: no data available

CREATE OR REPLACE VIEW taug.company_freshness_v AS
WITH latest_filing AS (
  SELECT DISTINCT ON (f.company_id)
    f.company_id,
    f.filing_type,
    f.filing_date,
    f.acceptance_datetime
  FROM taug.filings AS f
  WHERE f.filing_type IN ('10-K', '10-Q', '10-K/A', '10-Q/A')
  ORDER BY f.company_id, f.filing_date DESC
),
latest_statement AS (
  SELECT DISTINCT ON (fs.company_id)
    fs.company_id,
    fs.statement_type,
    fs.period_end,
    fs.published_at,
    fs.last_reported_at,
    fs.last_fetched_at,
    fs.last_verified_at
  FROM taug.financial_statements AS fs
  WHERE fs.status = 'active'
  ORDER BY fs.company_id, fs.period_end DESC
),
latest_metric AS (
  SELECT DISTINCT ON (sms.company_id)
    sms.company_id,
    sms.last_fetched_at,
    sms.as_of_date
  FROM taug.security_metric_snapshots AS sms
  WHERE sms.computation_status = 'ok'
  ORDER BY sms.company_id, sms.as_of_date DESC
),
latest_price AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    sps.price_date,
    sps.last_fetched_at
  FROM taug.security_price_snapshots AS sps
  JOIN taug.securities AS s ON s.id = sps.security_id
  ORDER BY s.company_id, sps.price_date DESC
),
latest_quality AS (
  SELECT DISTINCT ON (dqs.company_id)
    dqs.company_id,
    dqs.overall_score,
    dqs.created_at
  FROM taug.data_quality_scores AS dqs
  ORDER BY dqs.company_id, dqs.score_date DESC
)
SELECT
  c.id AS company_id,
  c.display_name,
  -- Filing freshness
  lf.filing_type AS latest_filing_type,
  lf.filing_date AS latest_filing_date,
  CASE
    WHEN lf.filing_date IS NULL THEN 'unknown'
    WHEN lf.filing_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'fresh'
    WHEN lf.filing_date >= CURRENT_DATE - INTERVAL '90 days' THEN 'aging'
    WHEN lf.filing_date >= CURRENT_DATE - INTERVAL '365 days' THEN 'stale'
    ELSE 'expired'
  END AS filing_freshness,
  -- Statement freshness
  ls.period_end AS latest_statement_period,
  ls.published_at AS latest_statement_published,
  ls.last_fetched_at AS statement_last_fetched,
  ls.last_verified_at AS statement_last_verified,
  CASE
    WHEN ls.published_at IS NULL THEN 'unknown'
    WHEN ls.published_at >= NOW() - INTERVAL '30 days' THEN 'fresh'
    WHEN ls.published_at >= NOW() - INTERVAL '90 days' THEN 'aging'
    WHEN ls.published_at >= NOW() - INTERVAL '365 days' THEN 'stale'
    ELSE 'expired'
  END AS statement_freshness,
  -- Metric freshness
  lm.as_of_date AS latest_metric_date,
  lm.last_fetched_at AS metric_last_fetched,
  CASE
    WHEN lm.last_fetched_at IS NULL THEN 'unknown'
    WHEN lm.last_fetched_at >= NOW() - INTERVAL '30 days' THEN 'fresh'
    WHEN lm.last_fetched_at >= NOW() - INTERVAL '90 days' THEN 'aging'
    WHEN lm.last_fetched_at >= NOW() - INTERVAL '365 days' THEN 'stale'
    ELSE 'expired'
  END AS metric_freshness,
  -- Price freshness
  lp.price_date AS latest_price_date,
  lp.last_fetched_at AS price_last_fetched,
  CASE
    WHEN lp.last_fetched_at IS NULL THEN 'unknown'
    WHEN lp.last_fetched_at >= NOW() - INTERVAL '1 day' THEN 'fresh'
    WHEN lp.last_fetched_at >= NOW() - INTERVAL '7 days' THEN 'aging'
    WHEN lp.last_fetched_at >= NOW() - INTERVAL '30 days' THEN 'stale'
    ELSE 'expired'
  END AS price_freshness,
  -- Quality score
  lq.overall_score AS quality_score,
  lq.created_at AS quality_scored_at
FROM taug.companies AS c
LEFT JOIN latest_filing AS lf ON lf.company_id = c.id
LEFT JOIN latest_statement AS ls ON ls.company_id = c.id
LEFT JOIN latest_metric AS lm ON lm.company_id = c.id
LEFT JOIN latest_price AS lp ON lp.company_id = c.id
LEFT JOIN latest_quality AS lq ON lq.company_id = c.id;

GRANT SELECT ON taug.company_freshness_v TO authenticated;
GRANT SELECT ON taug.company_freshness_v TO service_role;
