-- Phase 2: Countries reference table
--
-- Foundation table for canonical country codes. Supports future:
--   - Company domicile FK (companies.domicile_country_code → countries.iso2)
--   - Home market preference (user_settings.country_code)
--   - Exchange geography (exchanges.country → countries.iso2)
--   - Currency geography (currencies → countries)
--   - Macro data regionalization (FRED/BI/BPS → countries)
--
-- This is a foundation-only migration. No FK constraints into existing tables.
-- No application code changes. No worker changes. No backfills.

CREATE TABLE taug.countries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  iso2 TEXT NOT NULL UNIQUE,
  iso3 TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_countries_iso2 ON taug.countries(iso2);
CREATE INDEX idx_countries_region ON taug.countries(region) WHERE region IS NOT NULL;

ALTER TABLE taug.countries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read countries"
  ON taug.countries FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.countries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.countries TO service_role;

-- Seed data: 30 countries covering current project context and future expansion
--
-- Includes:
--   - All countries referenced in exchanges table (ID, US, GB, CN, JP)
--   - All countries referenced in companies.domicile_country_code (US)
--   - Minimum required set (ID, US, SG, JP)
--   - Southeast Asian markets (TH, MY, PH, VN, HK, TW)
--   - Major global markets (KR, IN, AU, DE, FR, CA, BR, MX)
--   - Additional reference markets (CH, NL, SE, NO, DK, FI, ZA, AE, SA, NZ)

INSERT INTO taug.countries (iso2, iso3, name, region) VALUES
  ('ID', 'IDN', 'Indonesia', 'Southeast Asia'),
  ('US', 'USA', 'United States', 'North America'),
  ('SG', 'SGP', 'Singapore', 'Southeast Asia'),
  ('JP', 'JPN', 'Japan', 'East Asia'),
  ('GB', 'GBR', 'United Kingdom', 'Europe'),
  ('CN', 'CHN', 'China', 'East Asia'),
  ('TH', 'THA', 'Thailand', 'Southeast Asia'),
  ('MY', 'MYS', 'Malaysia', 'Southeast Asia'),
  ('PH', 'PHL', 'Philippines', 'Southeast Asia'),
  ('VN', 'VNM', 'Vietnam', 'Southeast Asia'),
  ('HK', 'HKG', 'Hong Kong', 'East Asia'),
  ('TW', 'TWN', 'Taiwan', 'East Asia'),
  ('KR', 'KOR', 'South Korea', 'East Asia'),
  ('IN', 'IND', 'India', 'South Asia'),
  ('AU', 'AUS', 'Australia', 'Oceania'),
  ('DE', 'DEU', 'Germany', 'Europe'),
  ('FR', 'FRA', 'France', 'Europe'),
  ('CA', 'CAN', 'Canada', 'North America'),
  ('BR', 'BRA', 'Brazil', 'South America'),
  ('MX', 'MEX', 'Mexico', 'North America'),
  ('CH', 'CHE', 'Switzerland', 'Europe'),
  ('NL', 'NLD', 'Netherlands', 'Europe'),
  ('SE', 'SWE', 'Sweden', 'Europe'),
  ('NO', 'NOR', 'Norway', 'Europe'),
  ('DK', 'DNK', 'Denmark', 'Europe'),
  ('FI', 'FIN', 'Finland', 'Europe'),
  ('ZA', 'ZAF', 'South Africa', 'Africa'),
  ('AE', 'ARE', 'United Arab Emirates', 'Middle East'),
  ('SA', 'SAU', 'Saudi Arabia', 'Middle East'),
  ('NZ', 'NZL', 'New Zealand', 'Oceania')
ON CONFLICT (iso2) DO NOTHING;
