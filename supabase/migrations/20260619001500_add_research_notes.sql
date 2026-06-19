CREATE TABLE taug.research_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  company_id UUID REFERENCES taug.companies(id) ON DELETE SET NULL,
  security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  note_type TEXT NOT NULL DEFAULT 'general',
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (note_type IN ('general', 'thesis', 'due_diligence', 'earnings', 'macro', 'idea'))
);

CREATE INDEX idx_research_notes_user
  ON taug.research_notes(user_id, is_pinned DESC, updated_at DESC);

CREATE INDEX idx_research_notes_company
  ON taug.research_notes(company_id)
  WHERE company_id IS NOT NULL;

ALTER TABLE taug.research_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own notes"
  ON taug.research_notes FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.research_notes TO authenticated;
