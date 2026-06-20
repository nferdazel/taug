# Phase 2 Implementation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.**

---

## Executive Summary

Added a canonical `countries` reference table with 30 seed countries covering current project context and future international expansion. Foundation-only migration — no FK constraints, no application code changes, no worker changes, no backfills.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260620000800_add_countries.sql` | CREATE TABLE + indexes + RLS + seed data |

No other files modified.

---

## Migration Summary

### Table Definition

```sql
CREATE TABLE taug.countries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  iso2 TEXT NOT NULL UNIQUE,
  iso3 TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Indexes

- `idx_countries_iso2` on `iso2`
- `idx_countries_region` on `region` (partial, WHERE region IS NOT NULL)

### RLS

- Read: authenticated users
- Full CRUD: service_role

### Seed Data (30 countries)

| iso2 | iso3 | Name | Region |
|---|---|---|---|
| AE | ARE | United Arab Emirates | Middle East |
| AU | AUS | Australia | Oceania |
| BR | BRA | Brazil | South America |
| CA | CAN | Canada | North America |
| CH | CHE | Switzerland | Europe |
| CN | CHN | China | East Asia |
| DE | DEU | Germany | Europe |
| DK | DNK | Denmark | Europe |
| FI | FIN | Finland | Europe |
| FR | FRA | France | Europe |
| GB | GBR | United Kingdom | Europe |
| HK | HKG | Hong Kong | East Asia |
| ID | IDN | Indonesia | Southeast Asia |
| IN | IND | India | South Asia |
| JP | JPN | Japan | East Asia |
| KR | KOR | South Korea | East Asia |
| MX | MEX | Mexico | North America |
| MY | MYS | Malaysia | Southeast Asia |
| NL | NLD | Netherlands | Europe |
| NO | NOR | Norway | Europe |
| NZ | NZL | New Zealand | Oceania |
| PH | PHL | Philippines | Southeast Asia |
| SA | SAU | Saudi Arabia | Middle East |
| SE | SWE | Sweden | Europe |
| SG | SGP | Singapore | Southeast Asia |
| TH | THA | Thailand | Southeast Asia |
| TW | TWN | Taiwan | East Asia |
| US | USA | United States | North America |
| VN | VNM | Vietnam | Southeast Asia |
| ZA | ZAF | South Africa | Africa |

### Seed Rationale

| Category | Countries | Why |
|---|---|---|
| Required minimum | ID, US, SG, JP | Per Phase 2 spec |
| Exchange references | GB, CN | Exchanges table uses these codes |
| Company references | US | All SEC companies have domicile_country_code='US' |
| Southeast Asian context | TH, MY, PH, VN, HK, TW | Indonesia-first platform, regional expansion |
| Major global markets | KR, IN, AU, DE, FR, CA, BR, MX | Source strategy docs reference these |
| Additional reference | CH, NL, SE, NO, DK, FI, ZA, AE, SA, NZ | Common financial markets |

---

## Validation Queries

### Q1: Table exists

```sql
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_schema = 'taug' AND table_name = 'countries'
);
```

### Q2: Seed data exists

```sql
SELECT iso2, iso3, name, region FROM taug.countries ORDER BY iso2;
```

### Q3: iso2 codes are unique

```sql
SELECT iso2, COUNT(*) FROM taug.countries GROUP BY iso2 HAVING COUNT(*) > 1;
-- Expected: 0 rows (no duplicates)
```

### Q4: Country names are unique

```sql
SELECT name, COUNT(*) FROM taug.countries GROUP BY name HAVING COUNT(*) > 1;
-- Expected: 0 rows (no duplicates)
```

### Q5: Existing functionality unaffected

```sql
SELECT COUNT(*) FROM taug.exchanges;
SELECT COUNT(*) FROM taug.companies;
SELECT COUNT(*) FROM taug.securities;
```

---

## Validation Results

### Q1: Table exists ✅

Table created and queryable.

### Q2: Seed data ✅

30 countries inserted. All required countries (ID, US, SG, JP) present.

### Q3: iso2 uniqueness ✅

30 total, 30 unique, 0 duplicates.

### Q4: Name uniqueness ✅

30 total, 30 unique, 0 duplicates.

### Q5: Existing functionality ✅

| Table | Rows | Status |
|---|---|---|
| exchanges | 9 | Unchanged |
| companies | 10 | Unchanged |
| securities | 10 | Unchanged |

---

## Risks

### Migration risk

**Risk:** Low. Additive CREATE TABLE + INSERT. No existing tables modified.

### Future FK compatibility

**Risk:** `companies.domicile_country_code` stores TEXT values like 'US'. `countries.iso2` stores 'US'. Future FK migration will match on iso2. All existing company domicile values have matching countries in the seed data.

**Finding:** Safe. No FK introduced in this phase.

### Future home market compatibility

**Risk:** `user_settings.country_code` (Phase 3) will store TEXT values. Should reference `countries.iso2`. The seed data covers all likely home market values (ID, US, SG, JP, etc.).

**Finding:** Safe. Phase 3 can reference this table.

### Future exchange compatibility

**Risk:** `exchanges.country` stores values like 'ID', 'US', 'GB', 'JP', 'CN'. All have matching `countries.iso2` rows.

**Finding:** Safe. Future FK migration from `exchanges.country` to `countries.iso2` is straightforward.

---

## Rollback Instructions

```sql
DROP TABLE IF EXISTS taug.countries CASCADE;
```

This removes the table, indexes, RLS policies, and all seed data. No other tables are affected.

---

## Commit Information

- **Commit hash:** `pending` (will be filled after commit)
- **Commit message:** `feat(schema): add countries table with seed data`

---

## Notes For Architecture Review

1. **Taiwan iso2 code:** Uses `TW` (ISO 3166-1 alpha-2 standard). Not `TWN` (which is iso3).

2. **Denmark iso2 code:** Uses `DK` (ISO 3166-1 alpha-2 standard). Not `DNK` (which is iso3).

3. **No 'Global' entry:** The exchanges table has `country = 'Global'` for BINANCE. This is not a valid ISO country code. Future exchange normalization should handle this separately (e.g., NULL country_code or a special 'Global' entry outside the countries table).

4. **RLS:** Read access for authenticated users matches the pattern used by `exchanges`, `companies`, and `securities` tables.

5. **ON CONFLICT DO NOTHING:** The seed uses `ON CONFLICT (iso2) DO NOTHING` to be idempotent. Re-running the migration does not create duplicates.

6. **Ready for Phase 3:** Phase 3 adds `country_code TEXT` to `user_settings`. Future FK migration can reference `countries.iso2`.
