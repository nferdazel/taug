CREATE TABLE taug.raw_sources (
  id BIGSERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  source_type TEXT NOT NULL,
  region TEXT,
  is_official BOOLEAN NOT NULL DEFAULT FALSE,
  licensing_notes TEXT,
  access_method TEXT NOT NULL,
  default_latency_class TEXT NOT NULL DEFAULT 'official_delayed',
  active_from TIMESTAMPTZ,
  active_to TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_raw_sources_source_type
  ON taug.raw_sources(source_type);

CREATE INDEX idx_raw_sources_region
  ON taug.raw_sources(region)
  WHERE region IS NOT NULL;

ALTER TABLE taug.raw_sources ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.raw_sources TO service_role;
GRANT USAGE, SELECT ON SEQUENCE taug.raw_sources_id_seq TO service_role;

CREATE TABLE taug.raw_fetch_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_source_id BIGINT NOT NULL REFERENCES taug.raw_sources(id) ON DELETE RESTRICT,
  job_type TEXT NOT NULL,
  job_scope JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending',
  request_fingerprint TEXT,
  worker_version TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  error_code TEXT,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('pending', 'running', 'success', 'failed', 'partial'))
);

CREATE INDEX idx_raw_fetch_runs_source_started
  ON taug.raw_fetch_runs(raw_source_id, started_at DESC);

CREATE INDEX idx_raw_fetch_runs_status_started
  ON taug.raw_fetch_runs(status, started_at DESC);

ALTER TABLE taug.raw_fetch_runs ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.raw_fetch_runs TO service_role;

CREATE TABLE taug.raw_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_source_id BIGINT NOT NULL REFERENCES taug.raw_sources(id) ON DELETE RESTRICT,
  fetch_run_id UUID REFERENCES taug.raw_fetch_runs(id) ON DELETE SET NULL,
  document_type TEXT NOT NULL,
  document_url TEXT NOT NULL,
  storage_path TEXT NOT NULL UNIQUE,
  mime_type TEXT,
  content_hash TEXT NOT NULL,
  byte_size BIGINT,
  published_at TIMESTAMPTZ,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_raw_documents_source_hash
  ON taug.raw_documents(raw_source_id, content_hash);

CREATE INDEX idx_raw_documents_fetch_run
  ON taug.raw_documents(fetch_run_id)
  WHERE fetch_run_id IS NOT NULL;

CREATE INDEX idx_raw_documents_published
  ON taug.raw_documents(published_at DESC)
  WHERE published_at IS NOT NULL;

ALTER TABLE taug.raw_documents ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.raw_documents TO service_role;

CREATE TABLE taug.raw_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_source_id BIGINT NOT NULL REFERENCES taug.raw_sources(id) ON DELETE RESTRICT,
  fetch_run_id UUID REFERENCES taug.raw_fetch_runs(id) ON DELETE SET NULL,
  record_type TEXT NOT NULL,
  source_record_key TEXT NOT NULL,
  source_entity_key TEXT,
  observed_at TIMESTAMPTZ,
  effective_at TIMESTAMPTZ,
  payload_json JSONB NOT NULL,
  payload_hash TEXT NOT NULL,
  schema_version TEXT NOT NULL DEFAULT 'v1',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(raw_source_id, record_type, source_record_key, payload_hash)
);

CREATE INDEX idx_raw_records_source_entity
  ON taug.raw_records(raw_source_id, source_entity_key, created_at DESC)
  WHERE source_entity_key IS NOT NULL;

CREATE INDEX idx_raw_records_record_type
  ON taug.raw_records(record_type, created_at DESC);

CREATE INDEX idx_raw_records_payload_json
  ON taug.raw_records USING GIN(payload_json);

ALTER TABLE taug.raw_records ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.raw_records TO service_role;

CREATE TABLE taug.raw_document_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_record_id UUID NOT NULL REFERENCES taug.raw_records(id) ON DELETE CASCADE,
  raw_document_id UUID NOT NULL REFERENCES taug.raw_documents(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(raw_record_id, raw_document_id, link_type)
);

CREATE INDEX idx_raw_document_links_record
  ON taug.raw_document_links(raw_record_id);

CREATE INDEX idx_raw_document_links_document
  ON taug.raw_document_links(raw_document_id);

ALTER TABLE taug.raw_document_links ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.raw_document_links TO service_role;

CREATE TABLE taug.audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'info',
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actor_type TEXT NOT NULL DEFAULT 'system',
  actor_id TEXT,
  reference_type TEXT,
  reference_id TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical'))
);

CREATE INDEX idx_audit_events_entity
  ON taug.audit_events(entity_type, entity_id, occurred_at DESC);

CREATE INDEX idx_audit_events_event_type
  ON taug.audit_events(event_type, occurred_at DESC);

CREATE INDEX idx_audit_events_severity
  ON taug.audit_events(severity, occurred_at DESC);

ALTER TABLE taug.audit_events ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.audit_events TO service_role;

CREATE TABLE taug.validation_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  validation_rule TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('passed', 'warning', 'failed', 'resolved'))
);

CREATE INDEX idx_validation_events_entity
  ON taug.validation_events(entity_type, entity_id, detected_at DESC);

CREATE INDEX idx_validation_events_rule_status
  ON taug.validation_events(validation_rule, status, detected_at DESC);

ALTER TABLE taug.validation_events ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.validation_events TO service_role;

CREATE TABLE taug.restatement_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  prior_reference_id TEXT,
  new_reference_id TEXT,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  detection_method TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'detected',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status IN ('detected', 'validated', 'ignored'))
);

CREATE INDEX idx_restatement_events_entity
  ON taug.restatement_events(entity_type, entity_id, detected_at DESC);

ALTER TABLE taug.restatement_events ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON taug.restatement_events TO service_role;
