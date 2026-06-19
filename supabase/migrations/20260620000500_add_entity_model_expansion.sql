-- Sectors (GICS-like taxonomy)
CREATE TABLE taug.sectors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  taxonomy TEXT NOT NULL DEFAULT 'gics',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE taug.sectors ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.sectors TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.sectors TO service_role;

-- Industries (child of sectors)
CREATE TABLE taug.industries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sector_id UUID NOT NULL REFERENCES taug.sectors(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  taxonomy TEXT NOT NULL DEFAULT 'gics',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_industries_sector ON taug.industries(sector_id);

ALTER TABLE taug.industries ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.industries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.industries TO service_role;

-- Link companies to sectors/industries
ALTER TABLE taug.companies
  ADD COLUMN IF NOT EXISTS primary_sector_id UUID REFERENCES taug.sectors(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS primary_industry_id UUID REFERENCES taug.industries(id) ON DELETE SET NULL;

-- Company aliases (multiple names per company)
CREATE TABLE taug.company_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  alias TEXT NOT NULL,
  alias_type TEXT NOT NULL DEFAULT 'other',
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (alias_type IN ('legal_name', 'trading_name', 'former_name', 'ticker', 'other'))
);

CREATE INDEX idx_company_aliases_company ON taug.company_aliases(company_id);
CREATE INDEX idx_company_aliases_alias ON taug.company_aliases(alias);

ALTER TABLE taug.company_aliases ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.company_aliases TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.company_aliases TO service_role;

-- Company relationships (parent, subsidiary, merger, etc.)
CREATE TABLE taug.company_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  child_company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL DEFAULT 'subsidiary',
  effective_from DATE,
  effective_to DATE,
  source_document_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (relationship_type IN ('subsidiary', 'parent', 'spin_off', 'merged', 'acquired', 'joint_venture', 'other')),
  CHECK (parent_company_id != child_company_id)
);

CREATE INDEX idx_company_relationships_parent ON taug.company_relationships(parent_company_id);
CREATE INDEX idx_company_relationships_child ON taug.company_relationships(child_company_id);

ALTER TABLE taug.company_relationships ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.company_relationships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.company_relationships TO service_role;

-- Ownership snapshots (major shareholders)
CREATE TABLE taug.ownership_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  as_of_date DATE NOT NULL,
  owner_name TEXT NOT NULL,
  owner_type TEXT NOT NULL DEFAULT 'other',
  ownership_percent NUMERIC(8,4),
  shares_held NUMERIC(20,2),
  source_document_id UUID,
  last_fetched_at TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (owner_type IN ('institutional', 'insider', 'government', 'mutual_fund', 'etf', 'other'))
);

CREATE INDEX idx_ownership_snapshots_company ON taug.ownership_snapshots(company_id, as_of_date DESC);

ALTER TABLE taug.ownership_snapshots ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.ownership_snapshots TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.ownership_snapshots TO service_role;

-- Seed GICS sectors (top-level)
INSERT INTO taug.sectors (code, name, taxonomy) VALUES
  ('10', 'Energy', 'gics'),
  ('15', 'Materials', 'gics'),
  ('20', 'Industrials', 'gics'),
  ('25', 'Consumer Discretionary', 'gics'),
  ('30', 'Consumer Staples', 'gics'),
  ('35', 'Health Care', 'gics'),
  ('40', 'Financials', 'gics'),
  ('45', 'Information Technology', 'gics'),
  ('50', 'Communication Services', 'gics'),
  ('55', 'Utilities', 'gics'),
  ('60', 'Real Estate', 'gics')
ON CONFLICT (code) DO NOTHING;

-- Seed common industries
INSERT INTO taug.industries (sector_id, code, name, taxonomy)
SELECT s.id, i.code, i.name, 'gics'
FROM taug.sectors s
CROSS JOIN (VALUES
  ('4510', 'Software & Services', '45'),
  ('4520', 'Technology Hardware & Equipment', '45'),
  ('4530', 'Semiconductors & Semiconductor Equipment', '45'),
  ('3510', 'Pharmaceuticals, Biotechnology & Life Sciences', '35'),
  ('3520', 'Health Care Equipment & Services', '35'),
  ('4010', 'Banks', '40'),
  ('4020', 'Diversified Financials', '40'),
  ('4030', 'Insurance', '40'),
  ('2510', 'Automobiles & Components', '25'),
  ('2520', 'Consumer Durables & Apparel', '25'),
  ('2530', 'Consumer Services', '25'),
  ('2550', 'Retailing', '25'),
  ('3010', 'Food, Beverage & Tobacco', '30'),
  ('3020', 'Household & Personal Products', '30'),
  ('5010', 'Telecommunication Services', '50'),
  ('5020', 'Media & Entertainment', '50')
) AS i(code, name, sector_code)
WHERE s.code = i.sector_code
ON CONFLICT (code) DO NOTHING;
