# Prompt For Another Model

Use the prompt below as-is or with small adjustments.

```md
You are entering an existing repo in the middle of a deliberate foundation-first migration.

Before making any judgment, you must adopt these assumptions:

1. Missing Flutter research pages are expected right now.
2. Backend/data foundation work has intentionally been prioritized ahead of Flutter feature completeness.
3. You must not treat absent company pages, valuation pages, statement explorer pages, or screener UI as product defects unless you first prove they were supposed to be built already in the current phase.
4. You must distinguish between:
   - intentionally deferred UI work
   - actual regressions
   - actual architectural mistakes
5. You must optimize for:
   - data correctness
   - reliability
   - auditability
   - traceability
   - maintainability
   - sustainable sequencing

Project framing:

- This is not currently being built as a Bloomberg terminal clone.
- This is not a trading app.
- This is not an AI-first app.
- This is a financial research platform / investment research workspace.

Current repo strategy:

1. Preserve the existing Flutter shell and compact UX system.
2. Build raw immutable ingestion and lineage.
3. Build canonical company/security model.
4. Build statement normalization and restatement support.
5. Build serving/read models.
6. Only then move Flutter research surfaces onto those new read models.

Important:

- Do not recommend frontend-led refresh pipelines.
- Do not recommend Supabase Edge Functions as the long-term ETL backbone.
- Do not recommend chatbot/LLM features.
- Do not criticize the repo merely because research UI is incomplete.

What already exists and should be recognized as real progress:

- canonical `companies`, `securities`, `security_identifiers`
- `currencies`
- company-scoped `reporting_periods`
- raw ingestion spine
- SEC filing lineage and amendment linking
- statement layer schema
- SEC raw companyfacts ingestion
- SEC companyfacts parser MVP
- parser replay hardening
- first research serving views:
  - `company_research_summary_v`
  - `company_latest_statement_facts_v`
  - `filing_timeline_v`

What is still intentionally incomplete:

- company page UI
- statement explorer UI
- valuation snapshot UI
- screener UI
- quality/freshness UI

Your task:

1. Read these docs first:
   - `docs/ai-handoff-status.md`
   - `docs/research-platform-execution-checklist.md`
   - `docs/research-platform-schema-implementation-plan.md`
   - `docs/sec-filings-foundation-checklist.md`
2. Then analyze the repo using the current phase context.
3. When identifying gaps, classify each one as one of:
   - intentional defer
   - true defect
   - architectural debt
   - next-phase work
4. Do not produce shallow criticism that mistakes sequencing for failure.
5. If proposing next work, prefer serving/read models and data-quality improvements before major new Flutter surfaces.
```
