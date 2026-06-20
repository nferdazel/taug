# Phase 4 Implementation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.**

---

## Executive Summary

Backfilled `security_id` bridge columns on `watchlist_items`, `portfolio_holdings`, and `alerts` using ticker-only matching from `symbols` to `securities`. The bridge columns were added by `20260619000500` but remained NULL. This migration populates them.

**Scope:** Backfill only. No tables dropped. No columns removed. No application code changes. No worker changes. `symbols` table NOT deprecated.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260620001000_backfill_security_id_bridge.sql` | 3 UPDATE statements + verification comments |

No other files modified.

---

## Migration Summary

### What Changed

Three UPDATE statements backfill `security_id` from `symbol_id` via ticker matching:

```sql
UPDATE taug.watchlist_items wi
SET security_id = s.id
FROM taug.securities s
JOIN taug.symbols sym ON sym.ticker = s.ticker
WHERE wi.symbol_id = sym.id
  AND wi.security_id IS NULL;
```

Same pattern for `portfolio_holdings` and `alerts`.

### Tables Modified

| Table | Column Modified | Method |
|---|---|---|
| `watchlist_items` | `security_id` | UPDATE from NULL to matched UUID |
| `portfolio_holdings` | `security_id` | UPDATE from NULL to matched UUID |
| `alerts` | `security_id` | UPDATE from NULL to matched UUID |

### Tables NOT Modified

- `symbols` — untouched
- `securities` — untouched
- All other tables — untouched

---

## Matching Strategy

**Method:** Ticker-only

**Why ticker-only:**
- Securities have `exchange_id = NULL` (SEC pipeline creates them without exchange)
- Symbols have `exchange_id` set (IDX=1, NYSE=2, NASDAQ=3, etc.)
- `ticker + exchange` matching would return 0 results due to NULL mismatch
- 0 ticker collisions in current data

**Upgrade path:** Once securities become exchange-aware (exchange_id populated), upgrade to `ticker + exchange` matching.

### Data Inventory

| Metric | Value |
|---|---|
| Total symbols | 46 |
| Total securities | 10 |
| Ticker overlap | 7 |
| Matching tickers | AAPL, AMZN, GOOGL, JPM, META, MSFT, V |
| Symbols with no security | 39 (IDX=20, commodities=9, crypto=7, NVDA/TSLA/WMT=3) |
| Securities with no symbol | 3 (JNJ, PG, UNH) |
| Symbol ticker collisions | 0 |
| Security ticker collisions | 0 |

---

## Validation Queries

### Q1: Match counts per table

```sql
SELECT 'watchlist_items' AS tbl,
       COUNT(*) AS total,
       COUNT(security_id) AS bridged,
       COUNT(*) - COUNT(security_id) AS unmatched
FROM taug.watchlist_items
UNION ALL
SELECT 'portfolio_holdings',
       COUNT(*), COUNT(security_id), COUNT(*) - COUNT(security_id)
FROM taug.portfolio_holdings
UNION ALL
SELECT 'alerts',
       COUNT(*), COUNT(security_id), COUNT(*) - COUNT(security_id)
FROM taug.alerts;
```

### Q2: Collision check

```sql
SELECT sym.ticker, COUNT(DISTINCT s.id) AS security_count
FROM taug.symbols sym
JOIN taug.securities s ON s.ticker = sym.ticker
GROUP BY sym.ticker
HAVING COUNT(DISTINCT s.id) > 1;
```

### Q3: Existing functionality

```sql
SELECT COUNT(*) FROM taug.symbols;
SELECT COUNT(*) FROM taug.securities;
SELECT COUNT(*) FROM taug.companies;
```

---

## Validation Results

### Q1: Match counts

**Note:** `watchlist_items`, `portfolio_holdings`, and `alerts` do not have `service_role` SELECT grants. Exact counts cannot be verified via REST API. The migration ran without error.

**Expected results based on data analysis:**
- Rows with matching ticker in `symbols` → `securities`: backfilled
- Rows with no matching ticker: `security_id` remains NULL
- Rows with `security_id` already set: untouched (WHERE `security_id IS NULL`)

### Q2: Collision check ✅

0 collisions detected. Ticker-only matching is safe.

### Q3: Existing functionality ✅

| Table | Rows | Status |
|---|---|---|
| symbols | 46 | Unchanged |
| securities | 10 | Unchanged |
| companies | 10 | Unchanged |

---

## Match Statistics

| Category | Count | Notes |
|---|---|---|
| Symbols eligible for match | 7 | AAPL, AMZN, GOOGL, JPM, META, MSFT, V |
| Symbols unmatched | 39 | IDX (20), commodities (9), crypto (7), other US (3) |
| Securities unmatched | 3 | JNJ, PG, UNH (no symbol entry) |
| False matches | 0 | No collision risk |

---

## Risks

### False matches

**Risk:** Ticker-only matching could create false positives if same ticker exists on different exchanges.

**Finding:** 0 collisions in current data. Risk is zero today. Future risk mitigated by `symbols(exchange_id, ticker)` UNIQUE constraint.

### Ticker collision risk

**Risk:** If `symbols` grows to include same ticker on different exchanges (e.g., `AAPL` on NASDAQ and some other exchange), ticker-only matching would assign the wrong security.

**Finding:** Current data has 0 collisions. The `UNIQUE(exchange_id, ticker)` constraint on `symbols` prevents same-ticker-different-exchange within symbols. But `securities` doesn't enforce the same constraint with exchange_id (since it's NULL), so cross-table collisions are possible in theory.

### Future exchange-aware migration

**Risk:** When securities get `exchange_id` values, the ticker-only backfill may have assigned wrong securities for edge cases.

**Finding:** Current data has no edge cases. Future migration should re-verify and re-backfill with `ticker + exchange` matching.

### Downstream compatibility

**Risk:** Code reading `security_id` from these tables might get unexpected values.

**Finding:** No Dart code reads `security_id` from these tables. No worker code reads `security_id` from these tables. The bridge columns are currently unused by application code — they exist for future migration phases.

### Rollback complexity

**Risk:** Setting `security_id = NULL` reverses the backfill completely. No data loss.

**Finding:** Low complexity. Single UPDATE per table.

---

## Rollback Instructions

```sql
UPDATE taug.watchlist_items SET security_id = NULL;
UPDATE taug.portfolio_holdings SET security_id = NULL;
UPDATE taug.alerts SET security_id = NULL;
```

This reverses the backfill. Existing `symbol_id` values are untouched.

---

## Commit Information

- **Commit hash:** `pending` (will be filled after commit)
- **Commit message:** `feat(schema): backfill security_id bridge columns from symbol_id`

---

## Notes For Architecture Review

1. **Bridge columns already existed.** `20260619000500_add_canonical_entity_bridge.sql` added `security_id` columns to `watchlist_items`, `portfolio_holdings`, and `alerts`. This migration only populates them.

2. **No application impact.** No Dart code reads `security_id` from these tables. The company feature reads `security_id` from `company_research_summary_v` (which uses `securities` directly). Watchlist/portfolio/alerts features use `symbol_id` exclusively.

3. **service_role SELECT grants missing.** `watchlist_items`, `portfolio_holdings`, and `alerts` only have `authenticated` grants. Workers cannot read these tables via REST API. Future phases may need to add `service_role` grants.

4. **3 unmatched securities.** JNJ, PG, UNH have no corresponding `symbols` entry. They were added by the SEC pipeline but never had a `symbols` row created. These will remain `security_id = NULL` until either:
   - A `symbols` entry is created for them
   - Or the Dart code migrates to use `security_id` directly

5. **39 unmatched symbols.** IDX stocks, commodities, crypto, and NVDA/TSLA/WMT have no `securities` entry. These will remain `security_id = NULL` until a securities pipeline creates entries for them.

---

## Future Migration Considerations

### Phase 4b: Dart Read with Fallback

When building production UI, update Dart repositories to prefer `security_id` when available:

```dart
final securityId = json['security_id'] as String?;
final symbolId = json['symbol_id'] as int;
```

### Phase 4c: Dart Write Both

When adding to watchlist/portfolio, write both `symbol_id` and `security_id`.

### Phase 4d: Exchange-Aware Matching

When securities get `exchange_id` values, re-backfill with:

```sql
UPDATE taug.watchlist_items wi
SET security_id = s.id
FROM taug.securities s
JOIN taug.symbols sym ON sym.ticker = s.ticker
  AND sym.exchange_id = s.exchange_id
WHERE wi.symbol_id = sym.id
  AND wi.security_id IS NULL;
```

### Phase 4e: Deprecate symbols

After all features use `security_id`, remove `symbols` table. Far future.
