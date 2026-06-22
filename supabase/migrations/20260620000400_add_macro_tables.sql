-- Macro series metadata (normalized from FRED API)
CREATE TABLE taug.macro_series (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'other',
  frequency TEXT,
  units TEXT,
  source_record_id UUID REFERENCES taug.raw_records(id) ON DELETE SET NULL,
  last_observation_date DATE,
  last_fetched_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (category IN ('interest_rate', 'inflation', 'employment', 'gdp', 'trade', 'housing', 'sentiment', 'other'))
);

CREATE INDEX idx_macro_series_series_id ON taug.macro_series(series_id);
CREATE INDEX idx_macro_series_category ON taug.macro_series(category);

ALTER TABLE taug.macro_series ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.macro_series TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.macro_series TO service_role;

-- Macro observations (normalized time-series facts)
CREATE TABLE taug.macro_observations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id TEXT NOT NULL,
  observation_date DATE NOT NULL,
  value_numeric NUMERIC,
  raw_record_id UUID REFERENCES taug.raw_records(id) ON DELETE SET NULL,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(series_id, observation_date)
);

CREATE INDEX idx_macro_observations_series_date
  ON taug.macro_observations(series_id, observation_date DESC);

ALTER TABLE taug.macro_observations ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.macro_observations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.macro_observations TO service_role;

-- Serving view: latest observation per series
CREATE OR REPLACE VIEW taug.macro_latest_v AS
WITH ranked AS (
  SELECT
    ms.series_id,
    ms.title,
    ms.category,
    ms.frequency,
    ms.units,
    mo.observation_date,
    mo.value_numeric,
    ms.last_fetched_at,
    ROW_NUMBER() OVER (PARTITION BY ms.series_id ORDER BY mo.observation_date DESC) AS rn
  FROM taug.macro_series AS ms
  LEFT JOIN taug.macro_observations AS mo
    ON mo.series_id = ms.series_id
)
SELECT
  series_id,
  title,
  category,
  frequency,
  units,
  observation_date,
  value_numeric,
  last_fetched_at
FROM ranked
WHERE rn = 1;

GRANT SELECT ON taug.macro_latest_v TO authenticated;
GRANT SELECT ON taug.macro_latest_v TO service_role;

-- Seed FRED series definitions
INSERT INTO taug.macro_series (series_id, title, category, frequency, units)
VALUES
  ('DFF', 'Federal Funds Effective Rate', 'interest_rate', 'Daily', 'Percent'),
  ('CPIAUCSL', 'Consumer Price Index for All Urban Consumers', 'inflation', 'Monthly', 'Index 1982-1984=100'),
  ('UNRATE', 'Unemployment Rate', 'employment', 'Monthly', 'Percent'),
  ('GDP', 'Gross Domestic Product', 'gdp', 'Quarterly', 'Billions of Dollars'),
  ('DGS10', '10-Year Treasury Constant Maturity Rate', 'interest_rate', 'Daily', 'Percent')
ON CONFLICT (series_id) DO NOTHING;
