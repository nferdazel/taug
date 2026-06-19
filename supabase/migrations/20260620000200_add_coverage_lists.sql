CREATE TABLE taug.coverage_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES taug.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_coverage_lists_user
  ON taug.coverage_lists(user_id);

ALTER TABLE taug.coverage_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own coverage lists"
  ON taug.coverage_lists FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.coverage_lists TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.coverage_lists TO service_role;

CREATE TABLE taug.coverage_list_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coverage_list_id UUID NOT NULL REFERENCES taug.coverage_lists(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'active',
  priority SMALLINT NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('active', 'paused', 'archived'))
);

CREATE INDEX idx_coverage_list_items_list
  ON taug.coverage_list_items(coverage_list_id);

CREATE INDEX idx_coverage_list_items_company
  ON taug.coverage_list_items(company_id);

ALTER TABLE taug.coverage_list_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own coverage list items"
  ON taug.coverage_list_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM taug.coverage_lists cl
      WHERE cl.id = coverage_list_id AND cl.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM taug.coverage_lists cl
      WHERE cl.id = coverage_list_id AND cl.user_id = (select auth.uid())
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.coverage_list_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.coverage_list_items TO service_role;
