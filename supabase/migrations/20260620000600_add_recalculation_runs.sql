CREATE TABLE taug.recalculation_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_type TEXT NOT NULL,
  trigger_reason TEXT NOT NULL,
  trigger_reference_type TEXT,
  trigger_reference_id TEXT,
  scope JSONB NOT NULL DEFAULT '{}'::jsonb,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'running',
  processed_entities INTEGER NOT NULL DEFAULT 0,
  succeeded_entities INTEGER NOT NULL DEFAULT 0,
  failed_entities INTEGER NOT NULL DEFAULT 0,
  worker_version TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('running', 'success', 'partial', 'failed')),
  CHECK (run_type IN ('full_recompute', 'incremental', 'single_company', 'single_metric', 'filing_change', 'formula_change', 'price_update'))
);

CREATE INDEX idx_recalculation_runs_status ON taug.recalculation_runs(status, started_at DESC);
CREATE INDEX idx_recalculation_runs_trigger ON taug.recalculation_runs(trigger_reference_type, trigger_reference_id);

ALTER TABLE taug.recalculation_runs ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.recalculation_runs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.recalculation_runs TO service_role;
