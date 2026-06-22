CREATE OR REPLACE VIEW taug.company_statement_history_v AS
WITH primary_security AS (
  SELECT DISTINCT ON (s.company_id)
    s.company_id,
    s.id AS security_id,
    s.ticker,
    s.currency_code
  FROM taug.securities AS s
  ORDER BY s.company_id, s.is_primary_listing DESC, s.created_at DESC
),
active_statements AS (
  SELECT
    fs.id AS financial_statement_id,
    fs.company_id,
    fs.filing_id,
    fs.filing_version_id,
    fs.reporting_period_id,
    fs.statement_type,
    fs.statement_version,
    fs.period_start,
    fs.period_end,
    fs.published_at,
    fs.is_restated,
    fs.status,
    fs.parser_version
  FROM taug.financial_statements AS fs
  WHERE fs.status = 'active'
),
latest_fact_rows AS (
  SELECT
    as2.company_id,
    as2.financial_statement_id,
    as2.statement_type,
    as2.statement_version,
    as2.period_start,
    as2.period_end,
    as2.published_at,
    as2.is_restated,
    as2.status,
    as2.parser_version,
    sti.code,
    fsi.value_numeric,
    sti.unit_type
  FROM active_statements AS as2
  JOIN taug.financial_statement_items AS fsi
    ON fsi.financial_statement_id = as2.financial_statement_id
  LEFT JOIN taug.statement_taxonomy_items AS sti
    ON sti.id = fsi.taxonomy_item_id
)
SELECT
  c.id AS company_id,
  ps.ticker AS primary_ticker,
  lfr.statement_type,
  lfr.statement_version,
  lfr.period_start,
  lfr.period_end,
  lfr.published_at,
  lfr.is_restated,
  lfr.status AS statement_status,
  lfr.parser_version,
  cur.code AS currency_code,
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
    WHERE lfr.code = 'DepreciationDepletionAndAmortization'
  ) AS depreciation_amortization,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'ResearchAndDevelopmentExpense'
  ) AS rd_expense,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'SellingGeneralAndAdministrativeExpense'
  ) AS sga_expense,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'InterestIncomeExpenseNonoperatingNet'
  ) AS interest_income_net,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'IncomeTaxExpenseBenefit'
  ) AS income_tax,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'AssetsCurrent'
  ) AS current_assets,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'LiabilitiesCurrent'
  ) AS current_liabilities,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code IN (
      'LongTermDebtNoncurrent',
      'LongTermDebt'
    )
  ) AS long_term_debt,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'RetainedEarningsAccumulatedDeficit'
  ) AS retained_earnings,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EntityCommonStockSharesOutstanding'
  ) AS shares_outstanding,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EarningsPerShareBasic'
  ) AS eps_basic,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'EarningsPerShareDiluted'
  ) AS eps_diluted,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'NetCashProvidedByUsedInInvestingActivities'
  ) AS investing_cash_flow,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'NetCashProvidedByUsedInFinancingActivities'
  ) AS financing_cash_flow,
  MAX(lfr.value_numeric) FILTER (
    WHERE lfr.code = 'PaymentsToRepurchaseCommonStock'
  ) AS share_repurchases
FROM taug.companies AS c
LEFT JOIN primary_security AS ps
  ON ps.company_id = c.id
LEFT JOIN latest_fact_rows AS lfr
  ON lfr.company_id = c.id
LEFT JOIN taug.currencies AS cur
  ON cur.code = ps.currency_code
WHERE lfr.unit_type = 'monetary'
GROUP BY
  c.id,
  ps.ticker,
  lfr.statement_type,
  lfr.statement_version,
  lfr.period_start,
  lfr.period_end,
  lfr.published_at,
  lfr.is_restated,
  lfr.status,
  lfr.parser_version,
  cur.code;

GRANT SELECT ON taug.company_statement_history_v TO authenticated;
GRANT SELECT ON taug.company_statement_history_v TO service_role;

CREATE OR REPLACE VIEW taug.company_statement_items_v AS
WITH primary_security_items AS (
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
  psi.ticker AS primary_ticker,
  fs.id AS financial_statement_id,
  fs.statement_type,
  fs.statement_version,
  fs.period_end,
  fs.period_start,
  fs.published_at,
  fs.is_restated,
  fs.status AS statement_status,
  fsi.id AS item_id,
  fsi.lineage_source_type,
  fsi.lineage_source_id,
  sti.code AS taxonomy_code,
  sti.name AS taxonomy_name,
  sti.statement_type AS taxonomy_statement_type,
  sti.unit_type,
  sti.sign_convention,
  sti.taxonomy_source,
  fsi.value_numeric,
  fsi.value_text,
  fsi.unit,
  fsi.scale,
  fsi.decimals,
  fsi.fact_period_start,
  fsi.fact_period_end,
  fsi.fact_instant,
  fsi.is_reported,
  fsi.is_calculated,
  fsi.confidence_score,
  cur.code AS currency_code,
  fsi.created_at AS item_created_at
FROM taug.financial_statement_items AS fsi
JOIN taug.financial_statements AS fs
  ON fs.id = fsi.financial_statement_id
JOIN taug.companies AS c
  ON c.id = fs.company_id
LEFT JOIN primary_security_items AS psi
  ON psi.company_id = c.id
LEFT JOIN taug.statement_taxonomy_items AS sti
  ON sti.id = fsi.taxonomy_item_id
LEFT JOIN taug.currencies AS cur
  ON cur.id = fs.currency_id
WHERE fs.status = 'active';

GRANT SELECT ON taug.company_statement_items_v TO authenticated;
GRANT SELECT ON taug.company_statement_items_v TO service_role;
