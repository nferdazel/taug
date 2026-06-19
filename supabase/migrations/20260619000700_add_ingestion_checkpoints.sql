CREATE TABLE taug.ingestion_checkpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_source_id BIGINT NOT NULL REFERENCES taug.raw_sources(id) ON DELETE RESTRICT,
  job_type TEXT NOT NULL,
  checkpoint_scope_key TEXT NOT NULL,
  last_success_fetch_run_id UUID REFERENCES taug.raw_fetch_runs(id) ON DELETE SET NULL,
  checkpoint_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(raw_source_id, job_type, checkpoint_scope_key)
);

CREATE INDEX idx_ingestion_checkpoints_source_job
  ON taug.ingestion_checkpoints(raw_source_id, job_type, updated_at DESC);

ALTER TABLE taug.ingestion_checkpoints ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.ingestion_checkpoints TO service_role;
