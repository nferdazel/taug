-- Invalidation conditions: quantitative triggers that can disprove a thesis
CREATE TABLE IF NOT EXISTS taug.invalidation_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thesis_id UUID NOT NULL REFERENCES taug.investment_theses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  metric_code TEXT,
  operator TEXT NOT NULL,
  threshold_low NUMERIC(16,4),
  threshold_high NUMERIC(16,4),
  severity TEXT NOT NULL DEFAULT 'warning',
  status TEXT NOT NULL DEFAULT 'active',
  triggered_at TIMESTAMPTZ,
  triggered_value NUMERIC(16,4),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (severity IN ('warning', 'critical')),
  CHECK (status IN ('active', 'triggered', 'expired', 'retired')),
  CHECK (operator IN ('>', '<', '>=', '<=', '==', 'between'))
);

CREATE INDEX idx_invalidation_conditions_thesis
  ON taug.invalidation_conditions(thesis_id, status);

CREATE INDEX idx_invalidation_conditions_user
  ON taug.invalidation_conditions(user_id, status);

-- RLS
ALTER TABLE taug.invalidation_conditions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conditions" ON taug.invalidation_conditions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own conditions" ON taug.invalidation_conditions
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own conditions" ON taug.invalidation_conditions
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own conditions" ON taug.invalidation_conditions
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.invalidation_conditions TO authenticated;

-- Thesis assumptions: track key assumptions with optional quantitative bounds
CREATE TABLE IF NOT EXISTS taug.thesis_assumptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thesis_id UUID NOT NULL REFERENCES taug.investment_theses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  metric_code TEXT,
  operator TEXT,
  threshold_low NUMERIC(16,4),
  threshold_high NUMERIC(16,4),
  status TEXT NOT NULL DEFAULT 'active',
  last_checked_at TIMESTAMPTZ,
  last_checked_value NUMERIC(16,4),
  breach_detected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('active', 'confirmed', 'breached', 'expired', 'retired')),
  CHECK (operator IS NULL OR operator IN ('>', '<', '>=', '<=', '==', 'between'))
);

CREATE INDEX idx_thesis_assumptions_thesis
  ON taug.thesis_assumptions(thesis_id, status);

CREATE INDEX idx_thesis_assumptions_user
  ON taug.thesis_assumptions(user_id, status);

-- RLS
ALTER TABLE taug.thesis_assumptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own assumptions" ON taug.thesis_assumptions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own assumptions" ON taug.thesis_assumptions
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own assumptions" ON taug.thesis_assumptions
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete own assumptions" ON taug.thesis_assumptions
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.thesis_assumptions TO authenticated;

-- Breach detection view: join assumptions against current metric snapshots
CREATE OR REPLACE VIEW taug.assumption_check_v AS
SELECT
  ta.id AS assumption_id,
  ta.thesis_id,
  ta.user_id,
  ta.description,
  ta.metric_code,
  ta.operator,
  ta.threshold_low,
  ta.threshold_high,
  ta.status AS assumption_status,
  cms.value_numeric AS current_value,
  cms.computation_status,
  CASE
    WHEN ta.operator IS NULL OR ta.metric_code IS NULL THEN NULL
    WHEN cms.value_numeric IS NULL THEN NULL
    WHEN cms.computation_status != 'ok' THEN NULL
    WHEN ta.operator = '>' AND cms.value_numeric <= ta.threshold_low THEN TRUE
    WHEN ta.operator = '<' AND cms.value_numeric >= ta.threshold_low THEN TRUE
    WHEN ta.operator = '>=' AND cms.value_numeric < ta.threshold_low THEN TRUE
    WHEN ta.operator = '<=' AND cms.value_numeric > ta.threshold_low THEN TRUE
    WHEN ta.operator = '==' AND cms.value_numeric != ta.threshold_low THEN TRUE
    WHEN ta.operator = 'between' AND (cms.value_numeric < ta.threshold_low OR cms.value_numeric > ta.threshold_high) THEN TRUE
    ELSE FALSE
  END AS is_breached
FROM taug.thesis_assumptions ta
LEFT JOIN taug.company_metric_snapshot_v cms
  ON cms.metric_code = ta.metric_code
  AND cms.company_id = (SELECT it.company_id FROM taug.investment_theses it WHERE it.id = ta.thesis_id)
WHERE ta.status = 'active' AND ta.metric_code IS NOT NULL;

GRANT SELECT ON taug.assumption_check_v TO authenticated;
