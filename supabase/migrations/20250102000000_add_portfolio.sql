-- Portfolio Holdings table
CREATE TABLE taug.portfolio_holdings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  symbol_id INTEGER NOT NULL REFERENCES taug.symbols(id) ON DELETE CASCADE,
  quantity NUMERIC(16,6) NOT NULL CHECK (quantity > 0),
  avg_price NUMERIC(16,4) NOT NULL CHECK (avg_price > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_portfolio_holdings_user ON taug.portfolio_holdings(user_id);

ALTER TABLE taug.portfolio_holdings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own holdings"
  ON taug.portfolio_holdings FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.portfolio_holdings TO authenticated;
