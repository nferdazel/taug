-- ============================================================
-- TAUG SCHEMA — Financial Terminal
-- Schema: taug
-- ============================================================

CREATE SCHEMA IF NOT EXISTS taug;

-- Grant schema access
GRANT USAGE ON SCHEMA taug TO anon;
GRANT USAGE ON SCHEMA taug TO authenticated;
GRANT USAGE ON SCHEMA taug TO service_role;

-- ============================================================
-- MARKET METADATA (reference data, read-mostly)
-- ============================================================

CREATE TABLE taug.exchanges (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  country       TEXT NOT NULL,
  timezone      TEXT NOT NULL DEFAULT 'UTC',
  currency      TEXT NOT NULL DEFAULT 'USD',
  market_open   TIME,
  market_close  TIME,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE taug.symbols (
  id            SERIAL PRIMARY KEY,
  exchange_id   SMALLINT NOT NULL REFERENCES taug.exchanges(id),
  ticker        TEXT NOT NULL,
  name          TEXT NOT NULL,
  asset_class   TEXT NOT NULL DEFAULT 'equity',
  sector        TEXT,
  industry      TEXT,
  market_cap    BIGINT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  listed_at     DATE,
  delisted_at   DATE,
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(exchange_id, ticker)
);

CREATE INDEX idx_symbols_ticker ON taug.symbols(ticker);
CREATE INDEX idx_symbols_asset_class ON taug.symbols(asset_class);
CREATE INDEX idx_symbols_sector ON taug.symbols(sector) WHERE sector IS NOT NULL;
CREATE INDEX idx_symbols_metadata ON taug.symbols USING GIN(metadata);

-- ============================================================
-- USER PROFILES
-- ============================================================

CREATE TABLE taug.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE NOT NULL,
  display_name  TEXT,
  avatar_url    TEXT,
  timezone      TEXT NOT NULL DEFAULT 'Asia/Jakarta',
  locale        TEXT NOT NULL DEFAULT 'en-US',
  is_premium    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE taug.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON taug.profiles FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can update own profile"
  ON taug.profiles FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "Users can insert own profile"
  ON taug.profiles FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = id);

-- Auto-create profile on user registration
CREATE OR REPLACE FUNCTION taug.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO taug.profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION taug.handle_new_user();

GRANT SELECT, INSERT, UPDATE ON taug.profiles TO authenticated;

-- ============================================================
-- WATCHLISTS
-- ============================================================

CREATE TABLE taug.watchlists (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  name          TEXT NOT NULL DEFAULT 'My Watchlist',
  description   TEXT,
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order    SMALLINT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_watchlists_user ON taug.watchlists(user_id);

ALTER TABLE taug.watchlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own watchlists"
  ON taug.watchlists FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.watchlists TO authenticated;

-- ============================================================
-- WATCHLIST ITEMS
-- ============================================================

CREATE TABLE taug.watchlist_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  watchlist_id  UUID NOT NULL REFERENCES taug.watchlists(id) ON DELETE CASCADE,
  symbol_id     INTEGER NOT NULL REFERENCES taug.symbols(id) ON DELETE CASCADE,
  sort_order    SMALLINT NOT NULL DEFAULT 0,
  notes         TEXT,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(watchlist_id, symbol_id)
);

CREATE INDEX idx_watchlist_items_watchlist ON taug.watchlist_items(watchlist_id);
CREATE INDEX idx_watchlist_items_symbol ON taug.watchlist_items(symbol_id);

ALTER TABLE taug.watchlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own watchlist items"
  ON taug.watchlist_items FOR ALL
  TO authenticated
  USING (
    watchlist_id IN (
      SELECT id FROM taug.watchlists
      WHERE user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    watchlist_id IN (
      SELECT id FROM taug.watchlists
      WHERE user_id = (select auth.uid())
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.watchlist_items TO authenticated;

-- ============================================================
-- PRICE HISTORY CACHE (OHLCV candle data)
-- ============================================================

CREATE TABLE taug.price_history (
  id            BIGSERIAL PRIMARY KEY,
  symbol_id     INTEGER NOT NULL REFERENCES taug.symbols(id) ON DELETE CASCADE,
  interval      TEXT NOT NULL,
  ts            TIMESTAMPTZ NOT NULL,
  open          NUMERIC(16,4) NOT NULL,
  high          NUMERIC(16,4) NOT NULL,
  low           NUMERIC(16,4) NOT NULL,
  close         NUMERIC(16,4) NOT NULL,
  volume        BIGINT NOT NULL DEFAULT 0,
  turnover      NUMERIC(20,2),
  source        TEXT NOT NULL DEFAULT 'system',
  fetched_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(symbol_id, interval, ts)
);

CREATE INDEX idx_price_history_lookup ON taug.price_history(symbol_id, interval, ts DESC);
CREATE INDEX idx_price_history_ts ON taug.price_history(ts DESC);

ALTER TABLE taug.price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read price history"
  ON taug.price_history FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.price_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.price_history TO service_role;

-- ============================================================
-- NEWS ARTICLES CACHE
-- ============================================================

CREATE TABLE taug.news_articles (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id   TEXT UNIQUE,
  title         TEXT NOT NULL,
  summary       TEXT,
  content       TEXT,
  url           TEXT NOT NULL,
  source        TEXT NOT NULL,
  author        TEXT,
  published_at  TIMESTAMPTZ NOT NULL,
  image_url     TEXT,
  categories    TEXT[] DEFAULT '{}',
  symbols       INTEGER[] DEFAULT '{}',
  sentiment     NUMERIC(3,2),
  is_breaking   BOOLEAN NOT NULL DEFAULT FALSE,
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_news_published ON taug.news_articles(published_at DESC);
CREATE INDEX idx_news_symbols ON taug.news_articles USING GIN(symbols);
CREATE INDEX idx_news_categories ON taug.news_articles USING GIN(categories);
CREATE INDEX idx_news_source ON taug.news_articles(source, published_at DESC);

ALTER TABLE taug.news_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read news"
  ON taug.news_articles FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.news_articles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.news_articles TO service_role;

-- ============================================================
-- ECONOMIC CALENDAR EVENTS
-- ============================================================

CREATE TABLE taug.econ_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_key     TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL,
  country       TEXT NOT NULL,
  category      TEXT NOT NULL,
  importance    SMALLINT NOT NULL DEFAULT 1,
  actual        NUMERIC(16,4),
  forecast      NUMERIC(16,4),
  previous      NUMERIC(16,4),
  unit          TEXT,
  event_date    DATE NOT NULL,
  event_time    TIME,
  timezone      TEXT NOT NULL DEFAULT 'UTC',
  source        TEXT NOT NULL DEFAULT 'manual',
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_econ_events_date ON taug.econ_events(event_date, event_time);
CREATE INDEX idx_econ_events_country ON taug.econ_events(country, event_date);
CREATE INDEX idx_econ_events_importance ON taug.econ_events(importance, event_date) WHERE importance >= 2;

ALTER TABLE taug.econ_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read econ events"
  ON taug.econ_events FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.econ_events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.econ_events TO service_role;

-- ============================================================
-- USER ALERTS / NOTIFICATIONS
-- ============================================================

CREATE TABLE taug.alerts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  symbol_id     INTEGER REFERENCES taug.symbols(id) ON DELETE SET NULL,
  type          TEXT NOT NULL,
  condition     JSONB NOT NULL,
  label         TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  last_triggered_at TIMESTAMPTZ,
  trigger_count INTEGER NOT NULL DEFAULT 0,
  cooldown_mins SMALLINT NOT NULL DEFAULT 60,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_user ON taug.alerts(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_alerts_symbol ON taug.alerts(symbol_id) WHERE symbol_id IS NOT NULL;
CREATE INDEX idx_alerts_type ON taug.alerts(type, is_active);

ALTER TABLE taug.alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own alerts"
  ON taug.alerts FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.alerts TO authenticated;

-- ============================================================
-- USER PREFERENCES / SETTINGS
-- ============================================================

CREATE TABLE taug.user_settings (
  user_id           UUID PRIMARY KEY REFERENCES taug.profiles(id) ON DELETE CASCADE,
  density_mode      TEXT NOT NULL DEFAULT 'compact',
  default_interval  TEXT NOT NULL DEFAULT '1d',
  default_exchange  SMALLINT REFERENCES taug.exchanges(id),
  portfolio_currency TEXT NOT NULL DEFAULT 'USD',
  notification_prefs JSONB NOT NULL DEFAULT '{
    "email_alerts": true,
    "push_alerts": true,
    "breaking_news": true,
    "earnings_reminders": true
  }',
  dashboard_layout  JSONB DEFAULT '[]',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE taug.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own settings"
  ON taug.user_settings FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own settings"
  ON taug.user_settings FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own settings"
  ON taug.user_settings FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE ON taug.user_settings TO authenticated;

-- Auto-create settings on profile creation
CREATE OR REPLACE FUNCTION taug.handle_new_profile()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO taug.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_profile_created
  AFTER INSERT ON taug.profiles
  FOR EACH ROW EXECUTE FUNCTION taug.handle_new_profile();

-- ============================================================
-- SEED DATA: Exchanges
-- ============================================================

INSERT INTO taug.exchanges (code, name, country, timezone, currency, market_open, market_close) VALUES
  ('IDX', 'Indonesia Stock Exchange', 'ID', 'Asia/Jakarta', 'IDR', '09:00', '16:00'),
  ('NYSE', 'New York Stock Exchange', 'US', 'America/New_York', 'USD', '09:30', '16:00'),
  ('NASDAQ', 'NASDAQ', 'US', 'America/New_York', 'USD', '09:30', '16:00'),
  ('LSE', 'London Stock Exchange', 'GB', 'Europe/London', 'GBP', '08:00', '16:30'),
  ('TSE', 'Tokyo Stock Exchange', 'JP', 'Asia/Tokyo', 'JPY', '09:00', '15:00'),
  ('SSE', 'Shanghai Stock Exchange', 'CN', 'Asia/Shanghai', 'CNY', '09:30', '15:00'),
  ('BINANCE', 'Binance', 'Global', 'UTC', 'USD', NULL, NULL),
  ('COMEX', 'COMEX', 'US', 'America/New_York', 'USD', NULL, NULL),
  ('NYMEX', 'NYMEX', 'US', 'America/New_York', 'USD', NULL, NULL);

-- ============================================================
-- SEED DATA: Common Symbols (IDX + Commodities)
-- ============================================================

-- IDX Blue Chips
INSERT INTO taug.symbols (exchange_id, ticker, name, asset_class, sector) VALUES
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'BBCA.JK', 'Bank Central Asia', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'BBRI.JK', 'Bank Rakyat Indonesia', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'BMRI.JK', 'Bank Mandiri', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'BBNI.JK', 'Bank Negara Indonesia', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'TLKM.JK', 'Telkom Indonesia', 'equity', 'Communication Services'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'ASII.JK', 'Astra International', 'equity', 'Consumer Discretionary'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'UNVR.JK', 'Unilever Indonesia', 'equity', 'Consumer Staples'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'HMSP.JK', 'HM Sampoerna', 'equity', 'Consumer Staples'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'GGRM.JK', 'Gudang Garam', 'equity', 'Consumer Staples'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'KLBF.JK', 'Kalbe Farma', 'equity', 'Health Care'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'ICBP.JK', 'Indofood CBP', 'equity', 'Consumer Staples'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'INDF.JK', 'Indofood Sukses Makmur', 'equity', 'Consumer Staples'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'ADRO.JK', 'Adaro Energy', 'equity', 'Energy'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'PTBA.JK', 'Bukit Asam', 'equity', 'Energy'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'INTP.JK', 'Semen Indonesia', 'equity', 'Materials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'SMGR.JK', 'Semen Indonesia (Persero)', 'equity', 'Materials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'BSDE.JK', 'Bumi Serpong Damai', 'equity', 'Real Estate'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'CTRA.JK', 'Ciputra Development', 'equity', 'Real Estate'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'EXCL.JK', 'XL Axiata', 'equity', 'Communication Services'),
  ((SELECT id FROM taug.exchanges WHERE code = 'IDX'), 'ISAT.JK', 'Indosat Ooredoo Hutchison', 'equity', 'Communication Services');

-- Commodities
INSERT INTO taug.symbols (exchange_id, ticker, name, asset_class) VALUES
  ((SELECT id FROM taug.exchanges WHERE code = 'COMEX'), 'XAU/USD', 'Gold', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'COMEX'), 'XAG/USD', 'Silver', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'COMEX'), 'XPT/USD', 'Platinum', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'COMEX'), 'XPD/USD', 'Palladium', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYMEX'), 'CL/USD', 'Crude Oil WTI', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYMEX'), 'NG/USD', 'Natural Gas', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYMEX'), 'BRN/USD', 'Brent Crude Oil', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYMEX'), 'GC/USD', 'Gold Futures', 'commodity'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYMEX'), 'SI/USD', 'Silver Futures', 'commodity');

-- Major US Stocks
INSERT INTO taug.symbols (exchange_id, ticker, name, asset_class, sector) VALUES
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'AAPL', 'Apple Inc.', 'equity', 'Technology'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'MSFT', 'Microsoft Corporation', 'equity', 'Technology'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'GOOGL', 'Alphabet Inc.', 'equity', 'Technology'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'AMZN', 'Amazon.com Inc.', 'equity', 'Consumer Discretionary'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'NVDA', 'NVIDIA Corporation', 'equity', 'Technology'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'META', 'Meta Platforms Inc.', 'equity', 'Communication Services'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NASDAQ'), 'TSLA', 'Tesla Inc.', 'equity', 'Consumer Discretionary'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYSE'), 'JPM', 'JPMorgan Chase & Co.', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYSE'), 'V', 'Visa Inc.', 'equity', 'Financials'),
  ((SELECT id FROM taug.exchanges WHERE code = 'NYSE'), 'WMT', 'Walmart Inc.', 'equity', 'Consumer Staples');

-- Crypto (Binance)
INSERT INTO taug.symbols (exchange_id, ticker, name, asset_class) VALUES
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'BTC/USDT', 'Bitcoin', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'ETH/USDT', 'Ethereum', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'BNB/USDT', 'Binance Coin', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'SOL/USDT', 'Solana', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'XRP/USDT', 'XRP', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'ADA/USDT', 'Cardano', 'crypto'),
  ((SELECT id FROM taug.exchanges WHERE code = 'BINANCE'), 'DOGE/USDT', 'Dogecoin', 'crypto');
