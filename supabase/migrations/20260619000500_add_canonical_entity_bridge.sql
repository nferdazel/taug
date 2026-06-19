CREATE TABLE taug.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  domicile_country_code TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('active', 'inactive', 'delisted', 'merged'))
);

CREATE INDEX idx_companies_legal_name
  ON taug.companies(legal_name);

CREATE INDEX idx_companies_display_name
  ON taug.companies(display_name);

ALTER TABLE taug.companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read companies"
  ON taug.companies FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.companies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.companies TO service_role;

CREATE TABLE taug.securities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  exchange_id SMALLINT REFERENCES taug.exchanges(id) ON DELETE SET NULL,
  ticker TEXT NOT NULL,
  name TEXT NOT NULL,
  security_type TEXT NOT NULL DEFAULT 'common_stock',
  currency_code TEXT,
  is_primary_listing BOOLEAN NOT NULL DEFAULT FALSE,
  listed_on DATE,
  delisted_on DATE,
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('active', 'inactive', 'delisted'))
);

CREATE UNIQUE INDEX idx_securities_exchange_ticker_type
  ON taug.securities(exchange_id, ticker, security_type);

CREATE INDEX idx_securities_company
  ON taug.securities(company_id, is_primary_listing DESC, created_at DESC);

CREATE INDEX idx_securities_ticker
  ON taug.securities(ticker);

ALTER TABLE taug.securities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read securities"
  ON taug.securities FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.securities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.securities TO service_role;

CREATE TABLE taug.security_identifiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  security_id UUID NOT NULL REFERENCES taug.securities(id) ON DELETE CASCADE,
  identifier_type TEXT NOT NULL,
  identifier_value TEXT NOT NULL,
  effective_from TIMESTAMPTZ,
  effective_to TIMESTAMPTZ,
  source TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(identifier_type, identifier_value)
);

CREATE INDEX idx_security_identifiers_security
  ON taug.security_identifiers(security_id);

ALTER TABLE taug.security_identifiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read security identifiers"
  ON taug.security_identifiers FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.security_identifiers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.security_identifiers TO service_role;

ALTER TABLE taug.watchlist_items
  ADD COLUMN IF NOT EXISTS security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_watchlist_items_security
  ON taug.watchlist_items(security_id)
  WHERE security_id IS NOT NULL;

ALTER TABLE taug.portfolio_holdings
  ADD COLUMN IF NOT EXISTS security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_portfolio_holdings_security
  ON taug.portfolio_holdings(security_id)
  WHERE security_id IS NOT NULL;

ALTER TABLE taug.alerts
  ADD COLUMN IF NOT EXISTS security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_alerts_security
  ON taug.alerts(security_id)
  WHERE security_id IS NOT NULL;
