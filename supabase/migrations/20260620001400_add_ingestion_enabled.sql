-- Universe Management: Add ingestion_enabled flag to companies
--
-- Purpose: Enable database-driven company universe management.
-- Workers can discover target companies from the database
-- instead of relying on SEC_TARGET_CIKS environment variable.
--
-- All existing companies default to ingestion_enabled = TRUE.

ALTER TABLE taug.companies
  ADD COLUMN ingestion_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN taug.companies.ingestion_enabled IS
  'Controls whether this company is included in automated ingestion pipelines. Workers query this flag to discover target companies.';

CREATE INDEX idx_companies_ingestion_enabled
  ON taug.companies(ingestion_enabled)
  WHERE ingestion_enabled = TRUE;
