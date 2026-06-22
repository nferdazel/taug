-- Add security_id to portfolio_positions for direct securities relationship
-- This enables PostgREST nested select: securities!left(ticker)

ALTER TABLE taug.portfolio_positions
ADD COLUMN IF NOT EXISTS security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_security
  ON taug.portfolio_positions(security_id)
  WHERE security_id IS NOT NULL;
