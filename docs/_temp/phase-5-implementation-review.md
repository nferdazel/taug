# Phase 5 Implementation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.**

---

## Executive Summary

Extended the existing `raw_sources` table as a canonical source registry with attribution metadata. Added `source_id` FK on `macro_series` to link macro data to its source. Updated `macro_latest_v` to expose source metadata via JOIN. No hardcoded CASE logic — all attribution flows through the source registry.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260620001100_add_source_attribution.sql` | ALTER raw_sources + UPDATE seeds + ALTER macro_series + CREATE OR REPLACE VIEW |

No other files modified.

---

## Migration Summary

### raw_sources Extension

Added 4 columns:

| Column | Type | Default | Purpose |
|---|---|---|---|
| `organization` | TEXT | — | Organization responsible for source data |
| `source_url` | TEXT | — | Base URL of data source |
| `attribution_required` | BOOLEAN | FALSE | Whether attribution is required |
| `attribution_text` | TEXT | — | Display text for attribution |

### Existing Sources Updated

| Code | Organization | URL | Attribution Text |
|---|---|---|---|
| `sec_edgar` | U.S. Securities and Exchange Commission | https://www.sec.gov | Data sourced from SEC EDGAR (sec.gov) |
| `fred` | Federal Reserve Bank of St. Louis | https://fred.stlouisfed.org | Data provided by Federal Reserve Economic Data (FRED), Federal Reserve Bank of St. Louis |
| `bps` | Badan Pusat Statistik | https://www.bps.go.id | Data provided by Badan Pusat Statistik (BPS) - Statistics Indonesia |

### macro_series Linkage

Added `source_id BIGINT REFERENCES raw_sources(id)` to `macro_series`. Backfilled:

| Series Pattern | Source |
|---|---|
| `bps_*` | BPS (id=74) |
| All others | FRED (id=56) |

### macro_latest_v Updated

View now exposes 7 source metadata columns via LEFT JOIN to `raw_sources`:

- `source_code`
- `source_name`
- `source_organization`
- `source_url`
- `source_is_official`
- `source_attribution_required`
- `source_attribution_text`

---

## Registry Design

**raw_sources IS the source registry.** No new table needed.

Existing columns provide:
- `code` — unique identifier (source_code)
- `name` — display name
- `source_type` — classification (filings, api)
- `region` — geographic scope
- `is_official` — official source flag
- `licensing_notes` — licensing info
- `access_method` — how data is accessed
- `default_latency_class` — latency classification

New columns add:
- `organization` — responsible organization
- `source_url` — base URL
- `attribution_required` — attribution flag
- `attribution_text` — display text

---

## Validation Queries

### Q1: Registry exists with attribution fields

```sql
SELECT code, name, organization, source_url, attribution_required, attribution_text
FROM taug.raw_sources
ORDER BY id;
```

### Q2: Attribution data populated

```sql
SELECT code,
       (organization IS NOT NULL) AS has_org,
       (source_url IS NOT NULL) AS has_url,
       (attribution_text IS NOT NULL) AS has_text
FROM taug.raw_sources;
```

### Q3: Source lookup works

```sql
SELECT code, name, organization, attribution_text
FROM taug.raw_sources
WHERE code = 'fred';
```

### Q4: macro_series linked to raw_sources

```sql
SELECT series_id, source_id, title
FROM taug.macro_series
ORDER BY series_id;
```

### Q5: macro_latest_v exposes source metadata

```sql
SELECT series_id, title, source_code, source_name, source_organization,
       source_attribution_required, source_attribution_text
FROM taug.macro_latest_v
ORDER BY series_id;
```

### Q6: Existing functionality unchanged

```sql
SELECT COUNT(*) FROM taug.companies;
SELECT COUNT(*) FROM taug.securities;
```

---

## Validation Results

### Q1: Registry ✅

3 sources with all attribution fields populated.

### Q2: Attribution data ✅

All 3 sources have organization, source_url, and attribution_text.

### Q3: Source lookup ✅

FRED: "Federal Reserve Bank of St. Louis" — "Data provided by Federal Reserve Economic Data (FRED), Federal Reserve Bank of St. Louis"

### Q4: macro_series linkage ✅

| Pattern | source_id | Source |
|---|---|---|
| bps_1, bps_2, bps_8, bps_9 | 74 | BPS |
| CPIAUCSL, DFF, DGS10, GDP, UNRATE | 56 | FRED |

### Q5: macro_latest_v ✅

All 9 series expose full source metadata. BPS series show "Badan Pusat Statistik", FRED series show "Federal Reserve Economic Data".

### Q6: Existing functionality ✅

Companies: 10, Securities: 10. Unchanged.

---

## Risks

### Ingestion compatibility

**Risk:** Adding columns to `raw_sources` could break existing INSERT/UPDATE operations.

**Finding:** All new columns have defaults or are nullable. Existing `ensure_raw_source()` and `ensure_sec_source()` methods don't set these columns — they use the original column set. No breakage.

### Future licensing support

**Risk:** `licensing_notes` is TEXT, not structured. Future licensing workflows may need structured licensing data.

**Finding:** Current TEXT field is sufficient for foundation. Structured licensing (license_type, expiry, etc.) can be added in a future phase.

### Future trust model support

**Risk:** `is_official` is a simple boolean. Future trust models may need scoring, verification levels, etc.

**Finding:** Boolean is sufficient for foundation. Trust scoring is explicitly excluded from this phase.

### Future attribution support

**Risk:** `attribution_text` is static text. Future attribution may need dynamic rendering (e.g., "Data as of {date} from {source}").

**Finding:** Static text is sufficient for foundation. Dynamic rendering is a UI concern for a future phase.

### Migration complexity

**Risk:** Low. All changes are additive. No existing data modified (only new columns populated for existing rows).

---

## Rollback Instructions

```sql
-- Remove source_id from macro_series
ALTER TABLE taug.macro_series DROP COLUMN IF EXISTS source_id;

-- Restore original macro_latest_v
CREATE OR REPLACE VIEW taug.macro_latest_v AS
WITH ranked AS (
  SELECT
    ms.series_id, ms.title, ms.category, ms.frequency, ms.units,
    mo.observation_date, mo.value_numeric, ms.last_fetched_at,
    ROW_NUMBER() OVER (PARTITION BY ms.series_id ORDER BY mo.observation_date DESC) AS rn
  FROM taug.macro_series AS ms
  LEFT JOIN taug.macro_observations AS mo ON mo.series_id = ms.series_id
)
SELECT series_id, title, category, frequency, units, observation_date, value_numeric, last_fetched_at
FROM ranked WHERE rn = 1;

GRANT SELECT ON taug.macro_latest_v TO authenticated;
GRANT SELECT ON taug.macro_latest_v TO service_role;

-- Remove attribution columns from raw_sources
ALTER TABLE taug.raw_sources
  DROP COLUMN IF EXISTS organization,
  DROP COLUMN IF EXISTS source_url,
  DROP COLUMN IF EXISTS attribution_required,
  DROP COLUMN IF EXISTS attribution_text;
```

---

## Commit Information

- **Commit hash:** `pending` (will be filled after commit)
- **Commit message:** `feat(schema): add source attribution to raw_sources and link macro_series to source registry`

---

## Notes For Architecture Review

1. **raw_sources IS the registry.** No new table. The existing table already had `code`, `name`, `source_type`, `region`, `is_official`, `licensing_notes`. New columns fill the attribution gap.

2. **No hardcoded CASE logic.** Attribution flows through `source_id` FK → `raw_sources` JOIN. Adding a new source just requires inserting a row into `raw_sources` and setting `source_id` on the data rows.

3. **macro_latest_v is the serving layer.** Flutter can query this view to get source metadata for display. No need for separate attribution lookups.

4. **attribution_required flag.** UI can check this flag to decide whether to show attribution. All current sources have `attribution_required = TRUE`.

5. **Future sources.** When adding Bank Indonesia, OJK, IDX, etc., just:
   - INSERT into `raw_sources` with attribution fields
   - Set `source_id` on data rows
   - macro_latest_v automatically exposes the metadata

---

## Future Licensing Considerations

Current `licensing_notes` is free text. Future structured licensing could add:

```sql
ALTER TABLE taug.raw_sources
  ADD COLUMN license_type TEXT,        -- 'public_domain', 'open', 'restricted', 'commercial'
  ADD COLUMN license_url TEXT,         -- URL to license terms
  ADD COLUMN license_expiry DATE,      -- License expiry date
  ADD COLUMN redistribution_allowed BOOLEAN;
```

Not needed now. Current `licensing_notes` TEXT field is sufficient.

---

## Future Trust Model Considerations

Current `is_official` is a boolean. Future trust model could add:

```sql
ALTER TABLE taug.raw_sources
  ADD COLUMN trust_score NUMERIC(5,2),  -- 0-100 trust score
  ADD COLUMN verification_level TEXT,    -- 'unverified', 'community', 'official', 'governmental'
  ADD COLUMN last_audit_date DATE,       -- Last audit/verification date
  ADD COLUMN audit_notes TEXT;           -- Audit findings
```

Not needed now. Current `is_official` boolean is sufficient.
