-- Research questions: question-driven research workflow
CREATE TABLE IF NOT EXISTS taug.research_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  company_id UUID REFERENCES taug.companies(id) ON DELETE SET NULL,
  thesis_id UUID REFERENCES taug.investment_theses(id) ON DELETE SET NULL,
  question TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium',
  status TEXT NOT NULL DEFAULT 'open',
  answer TEXT,
  answered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  CHECK (status IN ('open', 'answered', 'abandoned'))
);

CREATE INDEX idx_research_questions_user
  ON taug.research_questions(user_id, status, priority, updated_at DESC);

CREATE INDEX idx_research_questions_company
  ON taug.research_questions(company_id)
  WHERE company_id IS NOT NULL;

CREATE INDEX idx_research_questions_thesis
  ON taug.research_questions(thesis_id)
  WHERE thesis_id IS NOT NULL;

-- RLS
ALTER TABLE taug.research_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own questions"
  ON taug.research_questions FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.research_questions TO authenticated;
