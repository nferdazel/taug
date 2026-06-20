# B2 — Universe Management Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Replaced environment-driven company selection with database-driven universe management. Added `ingestion_enabled` column to `companies` table. Workers now discover target CIKs from the database when `--ciks` and `SEC_TARGET_CIKS` are not provided. All 32 existing companies default to `ingestion_enabled = true`. 74 tests pass.

---

## Current State Audit

### SEC_TARGET_CIKS Dependencies (Before)

| File | Usage |
|---|---|
| `config.py` | Reads `SEC_TARGET_CIKS` env var |
| `cli.py` | `_resolve_ciks()` falls back to `config.sec_target_ciks` |
| `cli.py` | 3 command handlers use `_resolve_ciks()` |
| `.env.example` | Documents `SEC_TARGET_CIKS` |

### Company Selection Flow (Before)

```
CLI --ciks → SEC_TARGET_CIKS env var → Error
```

### Company Selection Flow (After)

```
CLI --ciks → SEC_TARGET_CIKS env var → Database (ingestion_enabled=true) → Error
```

---

## Universe Model

### Design Decision

**Extended `companies` table** with `ingestion_enabled` boolean. No new table needed.

**Rationale:**
- `companies` already has `status` field (active/inactive/delisted/merged)
- `ingestion_enabled` is a separate concern from `status`
- A company can be `active` but `ingestion_enabled=false` (e.g., temporarily paused)
- A company can be `ingestion_enabled=true` but `status=inactive` (e.g., historical data)

### Schema Change

```sql
ALTER TABLE taug.companies
  ADD COLUMN ingestion_enabled BOOLEAN NOT NULL DEFAULT TRUE;
```

All 32 existing companies default to `TRUE`.

---

## Worker Changes

### New Method: `list_ingestible_ciks()`

Returns `list[tuple[str, str]]` of `(company_id, cik)` for companies with `ingestion_enabled = true`.

Queries:
1. `companies` where `ingestion_enabled = true`
2. `security_identifiers` where `identifier_type = 'CIK'`
3. Joins via `securities.company_id`

### CLI Changes

**`_resolve_ciks()`** now returns empty tuple instead of raising when no CIKs provided.

**New `_resolve_ciks_from_db()`** queries database for ingestible CIKs.

**Command handlers** (sync-sec-submissions, sync-sec-companyfacts, parse-sec-companyfacts):
1. Try `--ciks` argument
2. Try `SEC_TARGET_CIKS` env var
3. Fall back to database (`ingestion_enabled = true`)
4. Error if all empty

---

## Validation Results

### Database Discovery

```
Discovered 32 companies from database
```

All 32 existing companies have `ingestion_enabled = true` and CIKs in `security_identifiers`.

### CLI Without SEC_TARGET_CIKS

```bash
# Explicit CIK (no env var needed)
sync-sec-submissions --ciks 0000320193  # ✅ works

# Database fallback (no CIKs, no env var)
sync-sec-submissions --max-companies 2  # ✅ discovers 2 from DB
```

### Regression Checks

| Check | Status |
|---|---|
| Ingestion works | ✅ |
| Companyfacts sync | ✅ |
| Metrics | ✅ |
| Screener | ✅ |
| Freshness | ✅ |
| Data quality | ✅ |
| 74 tests pass | ✅ |

---

## Migration Strategy

**Non-destructive.** `ALTER TABLE ADD COLUMN` with `DEFAULT TRUE`. All existing companies automatically enabled. No data migration needed.

**Future usage:**
- Disable a company: `UPDATE companies SET ingestion_enabled = false WHERE id = '...'`
- Enable a new company: `INSERT INTO companies ... ingestion_enabled = true`
- Bulk enable: `UPDATE companies SET ingestion_enabled = true WHERE ...`

---

## Risks

| Risk | Status |
|---|---|
| Existing companies lost | None — all default to TRUE |
| SEC_TARGET_CIKS still works | ✅ — preserved as override |
| Database query performance | Low — 32 companies, indexed |
| CIK join complexity | Low — simple 3-table join |

---

## Recommendation

**Accept.** SEC_TARGET_CIKS is no longer required for normal operation. Workers discover companies from the database. SEC_TARGET_CIKS preserved as optional override for one-off runs.
