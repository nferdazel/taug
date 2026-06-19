CREATE TABLE taug.investment_theses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  company_id UUID REFERENCES taug.companies(id) ON DELETE SET NULL,
  security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  stance TEXT NOT NULL DEFAULT 'neutral',
  summary TEXT NOT NULL DEFAULT '',
  thesis_body TEXT NOT NULL DEFAULT '',
  bull_case TEXT NOT NULL DEFAULT '',
  bear_case TEXT NOT NULL DEFAULT '',
  key_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  target_price NUMERIC(16,4),
  status TEXT NOT NULL DEFAULT 'open',
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (stance IN ('bullish', 'bearish', 'neutral')),
  CHECK (status IN ('open', 'closed', 'archived'))
);

CREATE INDEX idx_investment_theses_user
  ON taug.investment_theses(user_id, status, updated_at DESC);

CREATE INDEX idx_investment_theses_company
  ON taug.investment_theses(company_id)
  WHERE company_id IS NOT NULL;

ALTER TABLE taug.investment_theses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own theses"
  ON taug.investment_theses FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.investment_theses TO authenticated;
