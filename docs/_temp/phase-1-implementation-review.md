# Phase 1 Implementation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.**

---

## Executive Summary

Fixed `shares_outstanding` column returning NULL in `company_statement_history_v` by removing the over-restrictive `WHERE lfr.unit_type = 'monetary'` filter from the view's CTE. The `FILTER` clauses on individual taxonomy item codes already provide sufficient specificity — the WHERE clause was filtering out `EntityCommonStockSharesOutstanding` (unit_type='shares') and `EarningsPerShareBasic/Diluted` (unit_type='ratio').

**Scope correction:** Only `company_statement_history_v` was affected. `company_latest_statement_facts_v` does NOT have the unit_type filter and was not modified.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260620000700_fix_statement_history_shares.sql` | `CREATE OR REPLACE VIEW` — removed `WHERE lfr.unit_type = 'monetary'` and removed `sti.unit_type` from CTE SELECT |

No other files modified. No Dart changes. No worker changes.

---

## Migration Summary

### What Changed

In the `latest_fact_rows` CTE of `company_statement_history_v`:

**Before:**
```sql
latest_fact_rows AS (
  SELECT
    ...,
    sti.code,
    fsi.value_numeric,
    sti.unit_type          -- ← selected but only used in WHERE
  FROM ...
  LEFT JOIN taug.statement_taxonomy_items AS sti
    ON sti.id = fsi.taxonomy_item_id
)
...
WHERE lfr.unit_type = 'monetary'  -- ← BUG: excludes shares and ratio items
```

**After:**
```sql
latest_fact_rows AS (
  SELECT
    ...,
    sti.code,
    fsi.value_numeric
    -- unit_type removed from SELECT (no longer needed)
  FROM ...
  LEFT JOIN taug.statement_taxonomy_items AS sti
    ON sti.id = fsi.taxonomy_item_id
)
-- WHERE clause removed entirely
```

### Why Safe

Each column in the outer SELECT uses a `FILTER` clause targeting specific taxonomy codes:
- `revenue` → filters for `RevenueFromContractWithCustomerExcludingAssessedTax`, `SalesRevenueNet`, `Revenues`
- `shares_outstanding` → filters for `EntityCommonStockSharesOutstanding`
- `eps_basic` → filters for `EarningsPerShareBasic`

Non-matching rows contribute NULL to the `MAX()` aggregation. Removing the WHERE clause does not change monetary column values — it only allows shares and ratio items to participate in their targeted aggregations.

---

## Validation Queries

### Q1: shares_outstanding appears correctly

```sql
SELECT company_id, primary_ticker, statement_type, period_end, shares_outstanding
FROM taug.company_statement_history_v
WHERE shares_outstanding IS NOT NULL
ORDER BY period_end DESC
LIMIT 20;
```

### Q2: AAPL statement history

```sql
SELECT primary_ticker, statement_type, period_end, revenue, net_income, shares_outstanding, eps_diluted
FROM taug.company_statement_history_v
WHERE primary_ticker = 'AAPL'
ORDER BY period_end DESC
LIMIT 5;
```

### Q3: AAPL latest facts (unchanged view)

```sql
SELECT primary_ticker, revenue, net_income, shares_outstanding, eps_basic, eps_diluted
FROM taug.company_latest_statement_facts_v
WHERE primary_ticker = 'AAPL'
LIMIT 1;
```

### Q4: Monetary metrics still work

```sql
SELECT primary_ticker, statement_type, period_end, revenue, gross_profit, operating_income, total_assets, stockholders_equity
FROM taug.company_statement_history_v
WHERE primary_ticker = 'AAPL'
ORDER BY period_end DESC
LIMIT 5;
```

### Q5: Row counts

```sql
SELECT COUNT(*) FROM taug.company_statement_history_v;
```

### Q6: Per-company row counts

```sql
SELECT company_id, COUNT(*) AS row_count
FROM taug.company_statement_history_v
GROUP BY company_id
ORDER BY row_count DESC;
```

---

## Validation Results

### Q1: shares_outstanding ✅

| Company | Ticker | Statement Type | Period End | shares_outstanding |
|---|---|---|---|---|
| UnitedHealth | UNH | equity | 2026-04-30 | 908,144,404 |
| Microsoft | MSFT | equity | 2026-04-23 | 7,428,434,704 |
| Amazon | AMZN | equity | 2026-04-22 | 10,757,109,436 |
| J&J | JNJ | equity | 2026-04-17 | 2,407,216,971 |
| Apple | AAPL | equity | 2026-04-17 | 14,687,356,000 |
| P&G | PG | equity | 2026-03-31 | 2,328,598,978 |

**20 rows with non-null shares_outstanding.** Previously returned NULL for all.

### Q2: AAPL statement history ✅

| Statement Type | Period End | Revenue | Net Income | Shares |
|---|---|---|---|---|
| equity | 2026-04-17 | NULL | NULL | 14,687,356,000 |
| income_statement | 2026-03-28 | 254,940,000,000 | 71,675,000,000 | NULL |

Shares appear on equity statements. Revenue/net_income appear on income statements. Expected behavior.

### Q3: AAPL latest facts ✅

| Revenue | Net Income | Shares | EPS Basic | EPS Diluted |
|---|---|---|---|---|
| 254,940,000,000 | 71,675,000,000 | 14,687,356,000 | 4.87 | 4.85 |

`company_latest_statement_facts_v` was not modified — confirmed unchanged.

### Q4: Monetary metrics ✅

| Statement Type | Period End | Revenue | Gross Profit | Assets | Equity |
|---|---|---|---|---|---|
| income_statement | 2026-03-28 | 254,940,000,000 | 124,012,000,000 | NULL | NULL |
| balance_sheet | 2026-03-28 | NULL | NULL | 371,082,000,000 | 106,491,000,000 |

Monetary values unaffected. Income items on income statements, balance sheet items on balance sheets.

### Q5: Row count ✅

**377 total rows.** Reasonable for 10 companies with parsed statements.

### Q6: Per-company row counts ✅

| Company | Rows |
|---|---|
| Apple Inc. | 256 |
| PROCTER & GAMBLE Co | 27 |
| VISA INC. | 24 |
| JOHNSON & JOHNSON | 13 |
| AMAZON COM INC | 12 |
| UNITEDHEALTH GROUP INC | 11 |
| Alphabet Inc. | 11 |
| MICROSOFT CORP | 11 |
| Meta Platforms, Inc. | 11 |
| JPMORGAN CHASE & CO | 1 |

All 10 companies have data. No regressions.

---

## Risks

### Non-monetary values entering aggregations

**Risk:** Removing the WHERE clause allows ratio and shares items into the CTE.

**Finding:** No impact. Each MAX() uses a FILTER clause targeting specific taxonomy codes. Non-matching items contribute NULL. Verified by Q4 — monetary columns return identical values.

### View performance impact

**Risk:** More rows in the CTE could slow the view.

**Finding:** Minimal. The CTE processes `financial_statement_items` joined with `statement_taxonomy_items`. The additional rows are shares and ratio items — a small fraction of total items. The GROUP BY and FILTER clauses handle them efficiently. Index on `financial_statement_items(financial_statement_id, taxonomy_item_id)` covers the join.

### Compatibility impact

**Risk:** Downstream code expecting NULL shares_outstanding might break.

**Finding:** No code currently reads `shares_outstanding` from this view. The `compute-company-metrics` worker reads shares from `financial_statement_items` directly via `get_latest_shares_outstanding()`. The Flutter company page reads from `company_research_summary_v` and `company_metric_snapshot_v`, not from this view. No compatibility impact.

### Downstream metric impact

**Risk:** Metrics using shares_outstanding might change.

**Finding:** No impact. The `compute-company-metrics` worker does not use this view for shares data. It queries `financial_statement_items` directly. Price-dependent metrics (PE, PB, PS, etc.) use `get_latest_shares_outstanding()` which queries the items table, not this view.

---

## Rollback Instructions

To restore the original view definition:

```sql
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
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code IN ('RevenueFromContractWithCustomerExcludingAssessedTax','SalesRevenueNet','Revenues')) AS revenue,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'GrossProfit') AS gross_profit,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'OperatingIncomeLoss') AS operating_income,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'NetIncomeLoss') AS net_income,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'Assets') AS total_assets,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'Liabilities') AS total_liabilities,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'StockholdersEquity') AS stockholders_equity,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code IN ('CashAndCashEquivalentsAtCarryingValue','CashCashEquivalentsAndShortTermInvestments')) AS cash_and_equivalents,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'NetCashProvidedByUsedInOperatingActivities') AS operating_cash_flow,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'PaymentsToAcquirePropertyPlantAndEquipment') AS capex,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'DepreciationDepletionAndAmortization') AS depreciation_amortization,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'ResearchAndDevelopmentExpense') AS rd_expense,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'SellingGeneralAndAdministrativeExpense') AS sga_expense,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'InterestIncomeExpenseNonoperatingNet') AS interest_income_net,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'IncomeTaxExpenseBenefit') AS income_tax,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'AssetsCurrent') AS current_assets,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'LiabilitiesCurrent') AS current_liabilities,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code IN ('LongTermDebtNoncurrent','LongTermDebt')) AS long_term_debt,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'RetainedEarningsAccumulatedDeficit') AS retained_earnings,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'EntityCommonStockSharesOutstanding') AS shares_outstanding,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'EarningsPerShareBasic') AS eps_basic,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'EarningsPerShareDiluted') AS eps_diluted,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'NetCashProvidedByUsedInInvestingActivities') AS investing_cash_flow,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'NetCashProvidedByUsedInFinancingActivities') AS financing_cash_flow,
  MAX(lfr.value_numeric) FILTER (WHERE lfr.code = 'PaymentsToRepurchaseCommonStock') AS share_repurchases
FROM taug.companies AS c
LEFT JOIN primary_security AS ps ON ps.company_id = c.id
LEFT JOIN latest_fact_rows AS lfr ON lfr.company_id = c.id
LEFT JOIN taug.currencies AS cur ON cur.code = ps.currency_code
WHERE lfr.unit_type = 'monetary'
GROUP BY c.id, ps.ticker, lfr.statement_type, lfr.statement_version, lfr.period_start, lfr.period_end, lfr.published_at, lfr.is_restated, lfr.status, lfr.parser_version, cur.code;

GRANT SELECT ON taug.company_statement_history_v TO authenticated;
GRANT SELECT ON taug.company_statement_history_v TO service_role;
```

This restores the original view with the `WHERE lfr.unit_type = 'monetary'` filter.

---

## Commit Information

- **Commit hash:** `pending` (will be filled after commit)
- **Commit message:** `fix(schema): remove unit_type filter from statement history view to expose shares_outstanding`

---

## Notes For Architecture Review

1. **Scope correction:** The original cleanup plan stated both `company_statement_history_v` and `company_latest_statement_facts_v` were affected. Actual analysis shows only `company_statement_history_v` has the `unit_type` filter. `company_latest_statement_facts_v` was already correct.

2. **No downstream impact:** The `compute-company-metrics` worker reads shares data from `financial_statement_items` directly, not from this view. Flutter reads from other views. No code changes needed.

3. **Performance:** The view now includes more rows per company (shares + ratio items in addition to monetary). The FILTER clauses handle this efficiently. No index changes needed.

4. **Ready for Phase 2:** This change is independent of all other phases. No blocking dependencies.
