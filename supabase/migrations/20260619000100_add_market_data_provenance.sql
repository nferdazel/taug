CREATE TABLE taug.instrument_sources (
  id BIGSERIAL PRIMARY KEY,
  symbol_id INTEGER NOT NULL REFERENCES taug.symbols(id) ON DELETE CASCADE,
  vendor TEXT NOT NULL,
  vendor_symbol TEXT NOT NULL,
  asset_class TEXT NOT NULL,
  latency_class TEXT NOT NULL DEFAULT 'delayed',
  is_official BOOLEAN NOT NULL DEFAULT FALSE,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  source_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(symbol_id, vendor, vendor_symbol)
);

CREATE INDEX idx_instrument_sources_symbol_id
  ON taug.instrument_sources(symbol_id);

CREATE INDEX idx_instrument_sources_vendor_symbol
  ON taug.instrument_sources(vendor, vendor_symbol);

ALTER TABLE taug.instrument_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read instrument sources"
  ON taug.instrument_sources FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.instrument_sources TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.instrument_sources TO service_role;

CREATE TABLE taug.quote_snapshots (
  symbol_id INTEGER PRIMARY KEY REFERENCES taug.symbols(id) ON DELETE CASCADE,
  price NUMERIC(16,4) NOT NULL,
  previous_close NUMERIC(16,4),
  open NUMERIC(16,4),
  high NUMERIC(16,4),
  low NUMERIC(16,4),
  close NUMERIC(16,4),
  volume BIGINT NOT NULL DEFAULT 0,
  turnover NUMERIC(20,2),
  source_vendor TEXT NOT NULL,
  source_label TEXT NOT NULL,
  latency_class TEXT NOT NULL DEFAULT 'delayed',
  source_url TEXT,
  is_official BOOLEAN NOT NULL DEFAULT FALSE,
  is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  as_of TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quote_snapshots_updated_at
  ON taug.quote_snapshots(updated_at DESC);

CREATE INDEX idx_quote_snapshots_source_vendor
  ON taug.quote_snapshots(source_vendor, latency_class);

ALTER TABLE taug.quote_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read quote snapshots"
  ON taug.quote_snapshots FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.quote_snapshots TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.quote_snapshots TO service_role;

ALTER TABLE taug.news_articles
  ADD COLUMN IF NOT EXISTS source_label TEXT,
  ADD COLUMN IF NOT EXISTS latency_class TEXT NOT NULL DEFAULT 'syndicated',
  ADD COLUMN IF NOT EXISTS source_url TEXT,
  ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS fetched_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS as_of TIMESTAMPTZ;

UPDATE taug.news_articles
SET
  source_label = COALESCE(source_label, source),
  source_url = COALESCE(source_url, url),
  fetched_at = COALESCE(fetched_at, created_at),
  as_of = COALESCE(as_of, published_at)
WHERE source_label IS NULL
   OR source_url IS NULL
   OR fetched_at IS NULL
   OR as_of IS NULL;

ALTER TABLE taug.econ_events
  ADD COLUMN IF NOT EXISTS source_label TEXT,
  ADD COLUMN IF NOT EXISTS latency_class TEXT NOT NULL DEFAULT 'derived',
  ADD COLUMN IF NOT EXISTS source_url TEXT,
  ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS fetched_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS as_of TIMESTAMPTZ;

UPDATE taug.econ_events
SET
  source_label = COALESCE(source_label, source),
  fetched_at = COALESCE(fetched_at, NOW()),
  as_of = COALESCE(as_of, event_date::timestamptz)
WHERE source_label IS NULL
   OR fetched_at IS NULL
   OR as_of IS NULL;
