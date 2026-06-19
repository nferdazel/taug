CREATE OR REPLACE VIEW taug.company_research_summary_v AS
WITH primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.id AS security_id,
    s.ticker,
    s.currency_code
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
),
company_cik AS (
  SELECT
    si.security_id,
    si.identifier_value AS cik
  FROM taug.security_identifiers AS si
  WHERE si.identifier_type = 'CIK'
),
latest_filing AS (
  SELECT DISTINCT ON (f.company_id)
    f.company_id,
    f.id AS filing_id,
    f.filing_type,
    f.filing_date,
    f.report_date,
    f.acceptance_datetime,
    f.is_amendment
  FROM taug.filings AS f
  ORDER BY f.company_id, f.filing_date DESC, f.created_at DESC
),
latest_companyfacts AS (
  SELECT DISTINCT ON (rr.source_entity_key)
    rr.source_entity_key AS cik,
    rr.id AS raw_record_id,
    rr.created_at
  FROM taug.raw_records AS rr
  WHERE rr.record_type = 'sec_companyfacts'
  ORDER BY rr.source_entity_key, rr.created_at DESC
),
statement_rollup AS (
  SELECT
    fs.company_id,
    COUNT(*) AS statement_count,
    MAX(fs.period_end) AS latest_statement_period_end,
    MAX(fs.published_at) AS latest_statement_published_at,
    MAX(fs.last_verified_at) AS latest_statement_verified_at
  FROM taug.financial_statements AS fs
  WHERE fs.status = 'active'
  GROUP BY fs.company_id
),
filing_rollup AS (
  SELECT
    f.company_id,
    COUNT(*) AS filing_count
  FROM taug.filings AS f
  GROUP BY f.company_id
)
SELECT
  c.id AS company_id,
  c.display_name,
  c.legal_name,
  c.domicile_country_code,
  ps.security_id,
  ps.ticker AS primary_ticker,
  cc.cik,
  lf.filing_id AS latest_filing_id,
  lf.filing_type AS latest_filing_type,
  lf.filing_date AS latest_filing_date,
  lf.report_date AS latest_report_date,
  lf.acceptance_datetime AS latest_acceptance_datetime,
  lf.is_amendment AS latest_filing_is_amendment,
  COALESCE(fr.filing_count, 0) AS filing_count,
  COALESCE(sr.statement_count, 0) AS statement_count,
  sr.latest_statement_period_end,
  sr.latest_statement_published_at,
  sr.latest_statement_verified_at,
  lcf.raw_record_id AS latest_companyfacts_raw_record_id,
  lcf.created_at AS latest_companyfacts_at,
  CASE
    WHEN sr.latest_statement_published_at IS NULL THEN 'missing'
    WHEN sr.latest_statement_published_at >= NOW() - INTERVAL '120 days' THEN 'fresh'
    WHEN sr.latest_statement_published_at >= NOW() - INTERVAL '240 days' THEN 'stale'
    ELSE 'outdated'
  END AS statement_freshness_status
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN company_cik AS cc
  ON cc.security_id = ps.security_id
LEFT JOIN latest_filing AS lf
  ON lf.company_id = c.id
LEFT JOIN latest_companyfacts AS lcf
  ON lcf.cik = cc.cik
LEFT JOIN statement_rollup AS sr
  ON sr.company_id = c.id
LEFT JOIN filing_rollup AS fr
  ON fr.company_id = c.id;

GRANT SELECT ON taug.company_research_summary_v TO authenticated;
GRANT SELECT ON taug.company_research_summary_v TO service_role;

CREATE OR REPLACE VIEW taug.company_latest_statement_facts_v AS
WITH latest_statements AS (
  SELECT
    fs.company_id,
    fs.id AS financial_statement_id,
    fs.statement_type,
    fs.period_end,
    fs.period_start,
    fs.published_at,
    fs.currency_id,
    ROW_NUMBER() OVER (
      PARTITION BY fs.company_id, fs.statement_type
      ORDER BY fs.period_end DESC, fs.published_at DESC NULLS LAST, fs.created_at DESC
    ) AS row_num
  FROM taug.financial_statements AS fs
  WHERE fs.status = 'active'
),
primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.ticker
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
),
latest_fact_rows AS (
  SELECT
    ls.company_id,
    ls.statement_type,
    ls.period_end,
    ls.period_start,
    ls.published_at,
    ls.currency_id,
    sti.code,
    fsi.value_numeric
  FROM latest_statements AS ls
  JOIN taug.financial_statement_items AS fsi
    ON fsi.financial_statement_id = ls.financial_statement_id
  LEFT JOIN taug.statement_taxonomy_items AS sti
    ON sti.id = fsi.taxonomy_item_id
  WHERE ls.row_num = 1
)
SELECT
  c.id AS company_id,
  ps.ticker AS primary_ticker,
  MAX(lfr.period_end) AS latest_period_end,
  MAX(lfr.published_at) AS latest_statement_published_at,
  MAX(cur.code) AS statement_currency_code,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code IN (
      'RevenueFromContractWithCustomerExcludingAssessedTax',
      'SalesRevenueNet',
      'Revenues'
    )
  ) AS revenue,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'GrossProfit'
  ) AS gross_profit,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'OperatingIncomeLoss'
  ) AS operating_income,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'NetIncomeLoss'
  ) AS net_income,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'Assets'
  ) AS total_assets,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'Liabilities'
  ) AS total_liabilities,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'StockholdersEquity'
  ) AS stockholders_equity,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code IN (
      'CashAndCashEquivalentsAtCarryingValue',
      'CashCashEquivalentsAndShortTermInvestments'
    )
  ) AS cash_and_equivalents,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'NetCashProvidedByUsedInOperatingActivities'
  ) AS operating_cash_flow,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'PaymentsToAcquirePropertyPlantAndEquipment'
  ) AS capex,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EntityCommonStockSharesOutstanding'
  ) AS shares_outstanding,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EarningsPerShareBasic'
  ) AS eps_basic,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EarningsPerShareDiluted'
  ) AS eps_diluted
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN latest_fact_rows AS lfr
  ON lfr.company_id = c.id
LEFT JOIN taug.currencies AS cur
  ON cur.id = lfr.currency_id
GROUP BY c.id, ps.ticker;

GRANT SELECT ON taug.company_latest_statement_facts_v TO authenticated;
GRANT SELECT ON taug.company_latest_statement_facts_v TO service_role;

CREATE OR REPLACE VIEW taug.filing_timeline_v AS
SELECT
  f.company_id,
  fv.id AS filing_version_id,
  f.id AS filing_id,
  f.filing_key,
  f.filing_type,
  f.filing_date,
  f.report_date,
  f.acceptance_datetime,
  f.is_amendment,
  fv.version_number,
  fv.status AS filing_version_status,
  fv.is_restated AS filing_version_is_restated,
  fv.supersedes_filing_version_id,
  fv.superseded_by_filing_version_id,
  fv.raw_record_id,
  fv.raw_document_id,
  fv.detected_at,
  fv.ingested_at,
  fv.parser_version,
  fv.metadata AS filing_version_metadata,
  f.metadata AS filing_metadata
FROM taug.filings AS f
JOIN taug.filing_versions AS fv
  ON fv.filing_id = f.id;

GRANT SELECT ON taug.filing_timeline_v TO authenticated;
GRANT SELECT ON taug.filing_timeline_v TO service_role;
