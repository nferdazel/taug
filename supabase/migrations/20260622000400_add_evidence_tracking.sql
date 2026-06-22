-- Note-Thesis links: connect research notes as evidence to investment theses
CREATE TABLE IF NOT EXISTS taug.note_thesis_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID NOT NULL REFERENCES taug.research_notes(id) ON DELETE CASCADE,
  thesis_id UUID NOT NULL REFERENCES taug.investment_theses(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL DEFAULT 'supports',
  thesis_field TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (relationship IN ('supports', 'contradicts', 'updates', 'context')),
  CHECK (thesis_field IS NULL OR thesis_field IN (
    'bull_case', 'bear_case', 'assumptions', 'catalysts', 'risks', 'exit_conditions', 'summary'
  )),
  UNIQUE(note_id, thesis_id, thesis_field)
);

CREATE INDEX idx_note_thesis_links_thesis
  ON taug.note_thesis_links(thesis_id);

CREATE INDEX idx_note_thesis_links_note
  ON taug.note_thesis_links(note_id);

-- RLS
ALTER TABLE taug.note_thesis_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own note_thesis_links" ON taug.note_thesis_links
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM taug.research_notes rn WHERE rn.id = note_id AND rn.user_id = (select auth.uid()))
  );

CREATE POLICY "Users can insert own note_thesis_links" ON taug.note_thesis_links
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM taug.research_notes rn WHERE rn.id = note_id AND rn.user_id = (select auth.uid()))
  );

CREATE POLICY "Users can delete own note_thesis_links" ON taug.note_thesis_links
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM taug.research_notes rn WHERE rn.id = note_id AND rn.user_id = (select auth.uid()))
  );

GRANT SELECT, INSERT, DELETE ON taug.note_thesis_links TO authenticated;
