CREATE TABLE taug.policy_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  summary TEXT,
  url TEXT NOT NULL,
  source TEXT NOT NULL,
  source_label TEXT NOT NULL,
  source_url TEXT,
  country TEXT NOT NULL DEFAULT 'US',
  agency TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'policy',
  importance INTEGER NOT NULL DEFAULT 1 CHECK (importance BETWEEN 1 AND 3),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  latency_class TEXT NOT NULL DEFAULT 'syndicated',
  is_official BOOLEAN NOT NULL DEFAULT TRUE,
  is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  as_of TIMESTAMPTZ,
  published_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_policy_events_published_at
  ON taug.policy_events(published_at DESC);

CREATE INDEX idx_policy_events_agency
  ON taug.policy_events(agency, published_at DESC);

CREATE INDEX idx_policy_events_category
  ON taug.policy_events(category, importance DESC);

ALTER TABLE taug.policy_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read policy events"
  ON taug.policy_events FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON taug.policy_events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.policy_events TO service_role;
