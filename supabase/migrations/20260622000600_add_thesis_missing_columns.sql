-- Add missing columns to investment_theses
ALTER TABLE taug.investment_theses 
ADD COLUMN IF NOT EXISTS assumptions TEXT,
ADD COLUMN IF NOT EXISTS catalysts TEXT,
ADD COLUMN IF NOT EXISTS risks TEXT,
ADD COLUMN IF NOT EXISTS exit_conditions TEXT,
ADD COLUMN IF NOT EXISTS conviction TEXT NOT NULL DEFAULT 'low',
ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ;

-- Add CHECK constraint for conviction
ALTER TABLE taug.investment_theses 
ADD CONSTRAINT check_conviction CHECK (conviction IN ('low', 'medium', 'high'));
