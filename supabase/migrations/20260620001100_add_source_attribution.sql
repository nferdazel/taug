-- Phase 5: Source Registry Attribution Foundation
--
-- PURPOSE: Extend the existing raw_sources table as a canonical source registry
-- with attribution metadata. Link macro_series to raw_sources via source_id FK.
-- Update macro_latest_v to expose source metadata via JOIN.
--
-- DESIGN: raw_sources IS the source registry. No new table needed.
-- Attribution fields are added to raw_sources and populated for existing sources.
-- macro_series gets a source_id FK to raw_sources.
-- macro_latest_v exposes source_code, source_name, source_is_official.
--
-- SCOPE: Foundation only. No trust scoring. No licensing workflows.
-- No attribution rendering engine. No compliance checks. No UI.

-- Add attribution fields to raw_sources
ALTER TABLE taug.raw_sources
  ADD COLUMN organization TEXT,
  ADD COLUMN source_url TEXT,
  ADD COLUMN attribution_required BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN attribution_text TEXT;

COMMENT ON COLUMN taug.raw_sources.organization IS
  'Organization responsible for the source data (e.g., U.S. Securities and Exchange Commission).';

COMMENT ON COLUMN taug.raw_sources.source_url IS
  'Base URL of the data source (e.g., https://www.sec.gov).';

COMMENT ON COLUMN taug.raw_sources.attribution_required IS
  'Whether this source requires attribution when displaying derived data.';

COMMENT ON COLUMN taug.raw_sources.attribution_text IS
  'Display text for attribution (e.g., Data provided by Federal Reserve Economic Data (FRED)).';

-- Populate attribution for existing sources
UPDATE taug.raw_sources
SET
  organization = 'U.S. Securities and Exchange Commission',
  source_url = 'https://www.sec.gov',
  attribution_required = TRUE,
  attribution_text = 'Data sourced from SEC EDGAR (sec.gov)'
WHERE code = 'sec_edgar';

UPDATE taug.raw_sources
SET
  organization = 'Federal Reserve Bank of St. Louis',
  source_url = 'https://fred.stlouisfed.org',
  attribution_required = TRUE,
  attribution_text = 'Data provided by Federal Reserve Economic Data (FRED), Federal Reserve Bank of St. Louis'
WHERE code = 'fred';

UPDATE taug.raw_sources
SET
  organization = 'Badan Pusat Statistik',
  source_url = 'https://www.bps.go.id',
  attribution_required = TRUE,
  attribution_text = 'Data provided by Badan Pusat Statistik (BPS) - Statistics Indonesia'
WHERE code = 'bps';

-- Link macro_series to raw_sources
ALTER TABLE taug.macro_series
  ADD COLUMN source_id BIGINT REFERENCES taug.raw_sources(id) ON DELETE SET NULL;

COMMENT ON COLUMN taug.macro_series.source_id IS
  'Canonical source reference. Links to raw_sources registry for attribution and traceability.';

-- Backfill source_id for existing macro series
UPDATE taug.macro_series
SET source_id = rs.id
FROM taug.raw_sources rs
WHERE (
  (macro_series.series_id LIKE 'bps_%' AND rs.code = 'bps')
  OR (macro_series.series_id NOT LIKE 'bps_%' AND rs.code = 'fred')
);

-- Update macro_latest_v to expose source metadata
CREATE OR REPLACE VIEW taug.macro_latest_v AS
WITH ranked AS (
  SELECT
    ms.series_id,
    ms.title,
    ms.category,
    ms.frequency,
    ms.units,
    ms.source_id,
    mo.observation_date,
    mo.value_numeric,
    ms.last_fetched_at,
    ROW_NUMBER() OVER (PARTITION BY ms.series_id ORDER BY mo.observation_date DESC) AS rn
  FROM taug.macro_series AS ms
  LEFT JOIN taug.macro_observations AS mo
    ON mo.series_id = ms.series_id
)
SELECT
  r.series_id,
  r.title,
  r.category,
  r.frequency,
  r.units,
  r.observation_date,
  r.value_numeric,
  r.last_fetched_at,
  rs.code AS source_code,
  rs.name AS source_name,
  rs.organization AS source_organization,
  rs.source_url AS source_url,
  rs.is_official AS source_is_official,
  rs.attribution_required AS source_attribution_required,
  rs.attribution_text AS source_attribution_text
FROM ranked AS r
LEFT JOIN taug.raw_sources AS rs
  ON rs.id = r.source_id
WHERE r.rn = 1;

GRANT SELECT ON taug.macro_latest_v TO authenticated;
GRANT SELECT ON taug.macro_latest_v TO service_role;
