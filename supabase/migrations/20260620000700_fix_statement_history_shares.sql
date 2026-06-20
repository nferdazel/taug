-- Phase 1: Fix shares_outstanding in company_statement_history_v
--
-- BUG: The view's latest_fact_rows CTE includes WHERE lfr.unit_type = 'monetary'.
-- This filters out EntityCommonStockSharesOutstanding because its unit_type is 'shares',
-- not 'monetary'. The FILTER clauses on individual taxonomy item codes are already
-- sufficient to isolate the correct values — the WHERE clause is over-restrictive.
--
-- WHY SAFE TO REMOVE: Each MAX() aggregate uses a FILTER clause targeting specific
-- taxonomy codes (e.g., 'RevenueFromContractWithCustomerExcludingAssessedTax',
-- 'GrossProfit', 'EntityCommonStockSharesOutstanding'). Non-matching rows contribute
-- NULL to the MAX() aggregation, which is harmless. Removing the unit_type filter
-- does not change the behavior of monetary columns — it only allows shares_outstanding
-- and eps_basic/eps_diluted (unit_type='ratio') to participate in their respective
-- FILTER-targeted aggregations.
--
-- SCOPE: Only company_statement_history_v is affected. company_latest_statement_facts_v
-- does not have this filter and is not modified.
--
-- AFFECTED TABLES: None. View-only change.

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
    fsi.value_numeric
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
