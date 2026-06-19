CREATE TABLE taug.filings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  raw_source_id BIGINT NOT NULL REFERENCES taug.raw_sources(id) ON DELETE RESTRICT,
  filing_type TEXT NOT NULL,
  filing_key TEXT NOT NULL,
  filing_date DATE NOT NULL,
  acceptance_datetime TIMESTAMPTZ,
  report_date DATE,
  is_amendment BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(raw_source_id, filing_key)
);

CREATE INDEX idx_filings_company_date
  ON taug.filings(company_id, filing_date DESC);

CREATE INDEX idx_filings_type_date
  ON taug.filings(filing_type, filing_date DESC);

ALTER TABLE taug.filings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read filings"
  ON taug.filings FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.filings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.filings TO service_role;

CREATE TABLE taug.filing_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filing_id UUID NOT NULL REFERENCES taug.filings(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  raw_document_id UUID REFERENCES taug.raw_documents(id) ON DELETE SET NULL,
  raw_record_id UUID REFERENCES taug.raw_records(id) ON DELETE SET NULL,
  parser_version TEXT NOT NULL,
  is_restated BOOLEAN NOT NULL DEFAULT FALSE,
  supersedes_filing_version_id UUID REFERENCES taug.filing_versions(id) ON DELETE SET NULL,
  superseded_by_filing_version_id UUID REFERENCES taug.filing_versions(id) ON DELETE SET NULL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('active', 'superseded', 'ignored')),
  UNIQUE(filing_id, version_number)
);

CREATE UNIQUE INDEX idx_filing_versions_record_unique
  ON taug.filing_versions(filing_id, raw_record_id)
  WHERE raw_record_id IS NOT NULL;

CREATE INDEX idx_filing_versions_filing_detected
  ON taug.filing_versions(filing_id, detected_at DESC);

ALTER TABLE taug.filing_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read filing versions"
  ON taug.filing_versions FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.filing_versions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.filing_versions TO service_role;
