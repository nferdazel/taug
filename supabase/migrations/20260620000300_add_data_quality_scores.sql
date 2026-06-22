CREATE TABLE taug.data_quality_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES taug.companies(id) ON DELETE CASCADE,
  security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL,
  score_date DATE NOT NULL,
  overall_score NUMERIC(5,2),
  historical_coverage_score NUMERIC(5,2),
  completeness_score NUMERIC(5,2),
  validation_score NUMERIC(5,2),
  verification_score NUMERIC(5,2),
  freshness_score NUMERIC(5,2),
  restatement_support_score NUMERIC(5,2),
  component_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(company_id, score_date)
);

CREATE INDEX idx_data_quality_scores_company
  ON taug.data_quality_scores(company_id, score_date DESC);

ALTER TABLE taug.data_quality_scores ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON taug.data_quality_scores TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON taug.data_quality_scores TO service_role;
