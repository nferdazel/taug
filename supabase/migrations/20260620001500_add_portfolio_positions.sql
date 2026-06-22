-- Portfolio Positions: Decision journal for investment decisions
-- This table tracks investment decisions, not portfolio performance.
-- It is a decision journal, not a portfolio tracker.

CREATE TABLE taug.portfolio_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  thesis_id UUID REFERENCES taug.investment_theses(id) ON DELETE SET NULL,
  conviction TEXT NOT NULL DEFAULT 'low',
  entry_date DATE NOT NULL,
  entry_price NUMERIC(16,4),
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  exit_date DATE,
  exit_price NUMERIC(16,4),
  outcome TEXT,
  lessons_learned TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (conviction IN ('low', 'medium', 'high')),
  CHECK (status IN ('active', 'review_needed', 'closed')),
  CHECK (outcome IS NULL OR outcome IN ('correct', 'incorrect', 'partial'))
);

CREATE INDEX idx_portfolio_positions_user ON taug.portfolio_positions(user_id, status);
CREATE INDEX idx_portfolio_positions_company ON taug.portfolio_positions(company_id);

ALTER TABLE taug.portfolio_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own positions"
  ON taug.portfolio_positions FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.portfolio_positions TO authenticated;
GRANT SELECT ON taug.portfolio_positions TO service_role;
