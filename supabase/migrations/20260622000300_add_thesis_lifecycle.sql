-- Add last_reviewed_at to investment_theses
ALTER TABLE taug.investment_theses
ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ;

-- Create research_reviews table
CREATE TABLE IF NOT EXISTS taug.research_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  thesis_id UUID NOT NULL REFERENCES taug.investment_theses(id) ON DELETE CASCADE,
  reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  review_notes TEXT,
  conviction_before TEXT,
  conviction_after TEXT,
  stance_before TEXT,
  stance_after TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_research_reviews_user
  ON taug.research_reviews(user_id, reviewed_at DESC);

CREATE INDEX idx_research_reviews_thesis
  ON taug.research_reviews(thesis_id, reviewed_at DESC);

-- RLS
ALTER TABLE taug.research_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reviews" ON taug.research_reviews
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own reviews" ON taug.research_reviews
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT ON taug.research_reviews TO authenticated;

-- Thesis health view (open theses only)
CREATE OR REPLACE VIEW taug.thesis_health_v AS
SELECT
  t.id AS thesis_id,
  t.user_id,
  t.company_id,
  t.title,
  t.stance,
  t.status,
  t.created_at,
  t.updated_at,
  t.last_reviewed_at,
  CASE
    WHEN COALESCE(t.last_reviewed_at, t.created_at) >= NOW() - INTERVAL '7 days' THEN 'fresh'
    WHEN COALESCE(t.last_reviewed_at, t.created_at) >= NOW() - INTERVAL '30 days' THEN 'aging'
    WHEN COALESCE(t.last_reviewed_at, t.created_at) >= NOW() - INTERVAL '90 days' THEN 'stale'
    ELSE 'expired'
  END AS research_freshness
FROM taug.investment_theses t
WHERE t.status = 'open';

GRANT SELECT ON taug.thesis_health_v TO authenticated;
