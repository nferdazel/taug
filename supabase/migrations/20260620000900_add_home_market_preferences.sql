-- Phase 3: Home Market Preference Foundation
--
-- Adds minimum columns to user_settings to support future home market,
-- preferred exchange, and benchmark selection features.
--
-- This is a foundation-only migration. No UI changes. No worker changes.
-- No business logic. No recommendation engine. No personalization.
--
-- Column design:
--   country_code       TEXT   — user's legal/residential country (ISO2, e.g. 'ID', 'US', 'SG')
--   home_market_code   TEXT   — drives future dashboard, screener, macro defaults (ISO2)
--   preferred_exchange_codes TEXT[] — narrows future workflow defaults without limiting access
--   base_currency_code TEXT   — metric display currency (default 'USD')
--   benchmark_security_id UUID — default benchmark for comparison (FK to securities)
--
-- Excluded per plan:
--   news_priority_regions — TAUG has no news subsystem
--   recommendation/AI/sentiment preferences — deferred features

ALTER TABLE taug.user_settings
  ADD COLUMN country_code TEXT,
  ADD COLUMN home_market_code TEXT,
  ADD COLUMN preferred_exchange_codes TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN base_currency_code TEXT NOT NULL DEFAULT 'USD',
  ADD COLUMN benchmark_security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

COMMENT ON COLUMN taug.user_settings.country_code IS
  'ISO 3166-1 alpha-2 country code for user legal/residential country. Compatible with taug.countries.iso2. FK migration planned after countries table population.';

COMMENT ON COLUMN taug.user_settings.home_market_code IS
  'ISO 3166-1 alpha-2 country code for primary market context. Drives dashboard, screener, and macro defaults. Compatible with taug.countries.iso2.';

COMMENT ON COLUMN taug.user_settings.preferred_exchange_codes IS
  'Array of exchange codes to narrow workflow defaults. Does not restrict access to other exchanges. Example: {IDX, NASDAQ, NYSE}.';

COMMENT ON COLUMN taug.user_settings.base_currency_code IS
  'Default currency for metric display and portfolio valuation. References taug.currencies.code.';

COMMENT ON COLUMN taug.user_settings.benchmark_security_id IS
  'Default benchmark security for comparison (e.g., SPY, IHSG). References taug.securities.id.';

-- Grant service_role read access for future worker usage
GRANT SELECT ON taug.user_settings TO service_role;
