CREATE TABLE taug.currencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  symbol TEXT,
  minor_unit SMALLINT NOT NULL DEFAULT 2,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (char_length(code) = 3),
  CHECK (minor_unit >= 0)
);

CREATE INDEX idx_currencies_active
  ON taug.currencies(is_active, code);

ALTER TABLE taug.currencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read currencies"
  ON taug.currencies FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.currencies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.currencies TO service_role;

INSERT INTO taug.currencies (code, name, symbol, minor_unit)
VALUES
  ('USD', 'US Dollar', '$', 2),
  ('IDR', 'Indonesian Rupiah', 'Rp', 2),
  ('EUR', 'Euro', '€', 2),
  ('JPY', 'Japanese Yen', '¥', 0)
ON CONFLICT (code) DO NOTHING;

CREATE TABLE taug.reporting_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  period_type TEXT NOT NULL,
  fiscal_year INTEGER NOT NULL,
  fiscal_quarter SMALLINT,
  period_start DATE,
  period_end DATE NOT NULL,
  label TEXT NOT NULL,
  last_reported_at TIMESTAMPTZ,
  last_fetched_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (period_type IN ('annual', 'quarterly', 'ttm', 'instant')),
  CHECK (
    (period_type = 'quarterly' AND fiscal_quarter BETWEEN 1 AND 4)
    OR (period_type <> 'quarterly' AND fiscal_quarter IS NULL)
  ),
  CHECK (period_start IS NULL OR period_start <= period_end)
);

CREATE UNIQUE INDEX idx_reporting_periods_company_period_unique
  ON taug.reporting_periods(
    company_id,
    period_type,
    fiscal_year,
    COALESCE(fiscal_quarter, 0),
    period_end
  );

CREATE INDEX idx_reporting_periods_company_period_end
  ON taug.reporting_periods(company_id, period_end DESC);

ALTER TABLE taug.reporting_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read reporting periods"
  ON taug.reporting_periods FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.reporting_periods TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.reporting_periods TO service_role;

CREATE TABLE taug.statement_taxonomy_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  statement_type TEXT NOT NULL,
  unit_type TEXT,
  sign_convention TEXT NOT NULL DEFAULT 'natural',
  taxonomy_source TEXT NOT NULL,
  parent_taxonomy_item_id UUID REFERENCES taug.statement_taxonomy_items(id) ON DELETE SET NULL,
  is_core BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (statement_type IN ('income_statement', 'balance_sheet', 'cash_flow', 'equity', 'comprehensive_income', 'other')),
  CHECK (sign_convention IN ('natural', 'inverted'))
);

CREATE UNIQUE INDEX idx_statement_taxonomy_source_code
  ON taug.statement_taxonomy_items(taxonomy_source, code);

CREATE INDEX idx_statement_taxonomy_statement_type
  ON taug.statement_taxonomy_items(statement_type, is_core DESC, code);

ALTER TABLE taug.statement_taxonomy_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read statement taxonomy items"
  ON taug.statement_taxonomy_items FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.statement_taxonomy_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.statement_taxonomy_items TO service_role;

CREATE TABLE taug.financial_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL,
  filing_id UUID NOT NULL REFERENCES taug.filings(id) ON DELETE CASCADE,
  filing_version_id UUID NOT NULL REFERENCES taug.filing_versions(id) ON DELETE CASCADE,
  reporting_period_id UUID REFERENCES taug.reporting_periods(id) ON DELETE SET NULL,
  statement_type TEXT NOT NULL,
  statement_version INTEGER NOT NULL DEFAULT 1,
  currency_id UUID REFERENCES taug.currencies(id) ON DELETE SET NULL,
  period_start DATE,
  period_end DATE NOT NULL,
  published_at TIMESTAMPTZ,
  is_restated BOOLEAN NOT NULL DEFAULT FALSE,
  supersedes_statement_id UUID REFERENCES taug.financial_statements(id) ON DELETE SET NULL,
  superseded_by_statement_id UUID REFERENCES taug.financial_statements(id) ON DELETE SET NULL,
  last_reported_at TIMESTAMPTZ,
  last_fetched_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  parser_version TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (statement_type IN ('income_statement', 'balance_sheet', 'cash_flow', 'equity', 'comprehensive_income', 'other')),
  CHECK (statement_version >= 1),
  CHECK (status IN ('active', 'superseded', 'ignored')),
  CHECK (period_start IS NULL OR period_start <= period_end)
);

CREATE UNIQUE INDEX idx_financial_statements_version_unique
  ON taug.financial_statements(
    filing_version_id,
    statement_type,
    period_end,
    statement_version
  );

CREATE INDEX idx_financial_statements_company_statement_period
  ON taug.financial_statements(company_id, statement_type, period_end DESC);

CREATE INDEX idx_financial_statements_reporting_period
  ON taug.financial_statements(reporting_period_id)
  WHERE reporting_period_id IS NOT NULL;

ALTER TABLE taug.financial_statements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read financial statements"
  ON taug.financial_statements FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.financial_statements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.financial_statements TO service_role;

CREATE TABLE taug.financial_statement_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  financial_statement_id UUID NOT NULL REFERENCES taug.financial_statements(id) ON DELETE CASCADE,
  taxonomy_item_id UUID REFERENCES taug.statement_taxonomy_items(id) ON DELETE SET NULL,
  lineage_source_type TEXT NOT NULL,
  lineage_source_id TEXT NOT NULL,
  value_numeric NUMERIC,
  value_text TEXT,
  unit TEXT,
  scale INTEGER,
  decimals INTEGER,
  fact_period_start DATE,
  fact_period_end DATE,
  fact_instant DATE,
  is_reported BOOLEAN NOT NULL DEFAULT TRUE,
  is_calculated BOOLEAN NOT NULL DEFAULT FALSE,
  confidence_score NUMERIC(5,4),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    value_numeric IS NOT NULL
    OR value_text IS NOT NULL
  ),
  CHECK (is_reported OR is_calculated),
  CHECK (
    fact_period_end IS NULL
    OR fact_period_start IS NULL
    OR fact_period_start <= fact_period_end
  ),
  CHECK (
    confidence_score IS NULL
    OR (confidence_score >= 0 AND confidence_score <= 1)
  ),
  CHECK (
    lineage_source_type IN ('raw_record', 'raw_document', 'filing_version', 'xbrl_fact', 'manual')
  )
);

CREATE UNIQUE INDEX idx_financial_statement_items_lineage_unique
  ON taug.financial_statement_items(
    financial_statement_id,
    lineage_source_type,
    lineage_source_id
  );

CREATE INDEX idx_financial_statement_items_statement_taxonomy
  ON taug.financial_statement_items(financial_statement_id, taxonomy_item_id);

CREATE INDEX idx_financial_statement_items_taxonomy_numeric
  ON taug.financial_statement_items(taxonomy_item_id, value_numeric)
  WHERE value_numeric IS NOT NULL;

ALTER TABLE taug.financial_statement_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read financial statement items"
  ON taug.financial_statement_items FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.financial_statement_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.financial_statement_items TO service_role;
