# Phase 3 Implementation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.**

---

## Executive Summary

Added 5 home market preference columns to `user_settings` table. Foundation-only — no UI, no worker, no business logic changes. All new columns are nullable or have safe defaults. Existing user data preserved.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260620000900_add_home_market_preferences.sql` | ALTER TABLE user_settings — 5 new columns + comments + GRANT |

No other files modified.

---

## Migration Summary

### Columns Added

| Column | Type | Default | Nullable | FK | Purpose |
|---|---|---|---|---|---|
| `country_code` | TEXT | — | YES | No (compatible with `countries.iso2`) | User's legal/residential country |
| `home_market_code` | TEXT | — | YES | No (compatible with `countries.iso2`) | Primary market context for dashboard/screener |
| `preferred_exchange_codes` | TEXT[] | `{}` | NO | No | Workflow default exchanges |
| `base_currency_code` | TEXT | `'USD'` | NO | No | Metric display currency |
| `benchmark_security_id` | UUID | — | YES | YES → `securities.id` ON DELETE SET NULL | Default comparison benchmark |

### Design Decisions

**No FK on country_code/home_market_code.** These store ISO2 codes (e.g., 'ID', 'US') compatible with `taug.countries.iso2`. FK migration happens in a future phase after verifying data integrity.

**FK on benchmark_security_id.** This is the only FK added. Justified because `securities` is a mature canonical table and the benchmark reference needs referential integrity.

**service_role SELECT grant added.** Existing schema only granted to `authenticated`. Added `GRANT SELECT` for `service_role` so workers can read user settings in future (e.g., per-user metric computation).

**Excluded per plan:**
- `news_priority_regions` — TAUG has no news subsystem
- Recommendation/AI/sentiment preferences — deferred features

---

## Validation Queries

### Q1: New fields exist

```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'taug' AND table_name = 'user_settings'
AND column_name IN ('country_code', 'home_market_code', 'preferred_exchange_codes', 'base_currency_code', 'benchmark_security_id')
ORDER BY column_name;
```

### Q2: Existing users/settings preserved

```sql
SELECT user_id, density_mode, default_interval, portfolio_currency,
       country_code, home_market_code, preferred_exchange_codes,
       base_currency_code, benchmark_security_id
FROM taug.user_settings
LIMIT 5;
```

### Q3: Defaults correct

```sql
SELECT preferred_exchange_codes, base_currency_code
FROM taug.user_settings
LIMIT 1;
```

### Q4: Existing functionality unaffected

```sql
SELECT COUNT(*) FROM taug.profiles;
SELECT COUNT(*) FROM taug.exchanges;
SELECT COUNT(*) FROM taug.companies;
SELECT COUNT(*) FROM taug.securities;
```

---

## Validation Results

### Q1: New fields exist ✅

All 5 columns present in `user_settings`. Total columns: 14 (was 9).

### Q2: Existing settings preserved ✅

| Field | Value | Expected |
|---|---|---|
| density_mode | compact | compact |
| default_interval | 1d | 1d |
| portfolio_currency | USD | USD |
| country_code | NULL | NULL |
| home_market_code | NULL | NULL |
| preferred_exchange_codes | [] | [] |
| base_currency_code | USD | USD |
| benchmark_security_id | NULL | NULL |

### Q3: Defaults correct ✅

- `preferred_exchange_codes` defaults to `{}`
- `base_currency_code` defaults to `USD`

### Q4: Existing functionality ✅

| Table | Rows | Status |
|---|---|---|
| profiles | 1 | Unchanged |
| exchanges | 9 | Unchanged |
| companies | 10 | Unchanged |
| securities | 10 | Unchanged |

---

## Risks

### Migration risk

**Risk:** Low. ALTER TABLE ADD COLUMN with defaults/nullable. No existing rows modified. No data loss possible.

### Future FK compatibility

**Risk:** `country_code` and `home_market_code` store TEXT values compatible with `countries.iso2`. Future FK migration:
```sql
ALTER TABLE taug.user_settings
  ADD CONSTRAINT fk_user_settings_country
  FOREIGN KEY (country_code) REFERENCES taug.countries(iso2);
```
Requires `countries` table to have matching iso2 values. Phase 2 seeded 30 countries covering all likely values.

### Future countries integration

**Risk:** Low. All likely country codes (ID, US, SG, JP, GB, CN, etc.) exist in `countries` table from Phase 2.

### Future exchange integration

**Risk:** `preferred_exchange_codes` stores TEXT array. Future normalization could reference `exchanges.code`. No FK possible on array columns in PostgreSQL — would need a junction table.

### Future benchmark support

**Risk:** `benchmark_security_id` FK to `securities` is active. If a security is deleted, benchmark becomes NULL. This is the correct behavior — if the benchmark security is removed, the user should select a new one.

---

## Rollback Instructions

```sql
ALTER TABLE taug.user_settings
  DROP COLUMN IF EXISTS country_code,
  DROP COLUMN IF EXISTS home_market_code,
  DROP COLUMN IF EXISTS preferred_exchange_codes,
  DROP COLUMN IF EXISTS base_currency_code,
  DROP COLUMN IF EXISTS benchmark_security_id;
```

This removes the 5 new columns. Existing columns (density_mode, default_interval, etc.) are unaffected.

---

## Commit Information

- **Commit hash:** `pending` (will be filled after commit)
- **Commit message:** `feat(schema): add home market preference columns to user_settings`

---

## Notes For Architecture Review

1. **`portfolio_currency` vs `base_currency_code`:** The existing `portfolio_currency` column (default 'USD') serves portfolio valuation. The new `base_currency_code` (default 'USD') serves metric display. These could be unified in a future cleanup, but for now they serve different purposes.

2. **`default_exchange` vs `preferred_exchange_codes`:** The existing `default_exchange` (SMALLINT FK to exchanges) is a single exchange. The new `preferred_exchange_codes` (TEXT array) is multiple exchanges. The single-exchange column could be deprecated in favor of the array column in a future cleanup.

3. **No `news_priority_regions`:** Excluded per feedback. TAUG has no news subsystem. Adding this field would create unnecessary migration debt.

4. **RLS:** Existing RLS policies (`Users can read/update/insert own settings`) apply to new columns automatically. No new policies needed.

---

## Future Considerations

1. **FK migration for country_code:** After verifying all existing values map to `countries.iso2`, add FK constraint.

2. **Unify portfolio_currency and base_currency_code:** Consider deprecating `portfolio_currency` in favor of `base_currency_code` when UI is built.

3. **Junction table for preferred_exchanges:** If exchange preferences need more metadata (priority, default interval per exchange), create a `user_preferred_exchanges` junction table.

4. **Default benchmark seeding:** Pre-populate common benchmarks (SPY, QQQ, IHSG) as options for user selection.
