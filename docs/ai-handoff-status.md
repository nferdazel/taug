# Taug AI Handoff Status

Last updated: 2026-06-19

## Purpose

This file is the fast handoff context for any new AI model or human contributor.

Read this before:

- auditing the repo
- proposing roadmap changes
- critiquing missing features
- implementing Flutter surfaces

If this file conflicts with a shallow repo impression, trust this file and then verify the linked docs.

## Current Reality

Taug is a financial research platform / investment research workspace.

Phase 4–6 of the execution checklist are complete. The data foundation, serving views, metric engine, and core Flutter research pages are implemented.

## Product Direction

Current target:

- financial research platform
- investment research workspace
- company-first research system

Not the target:

- trading platform
- AI-first app
- chatbot product
- real-time terminal moat

## What Is Intentionally Frozen

- terminal-first expansion
- order book / running trades as strategy
- AI/chatbot/LLM features
- frontend-driven ingestion
- Supabase Edge Functions as long-term ETL backbone

## What Already Exists

### Flutter research pages

- company research page (summary, metrics, statement history, quality, notes, theses)
- screener page (sortable metric table with quality indicators)
- valuation snapshot page (per-company metric cards)
- company selector with search dialog
- statement line items drill-down

### Flutter workspace (preserved from terminal era)

- auth flow
- compact shell and navigation (12 tabs)
- watchlists
- portfolios
- settings
- compact design system

### Data foundation

- canonical `companies`, `securities`, `security_identifiers`
- `currencies`, company-scoped `reporting_periods`
- immutable raw ingestion spine (`raw_sources`, `raw_documents`, `raw_records`, `raw_fetch_runs`, `raw_document_links`)
- SEC filing lineage (`filings`, `filing_versions`) with amendment supersession
- statement layer (`statement_taxonomy_items`, `financial_statements`, `financial_statement_items`)
- SEC raw companyfacts ingestion + parser (35 XBRL concepts)
- parser replay hardened (bulk lookup, preloaded caches, batched inserts)
- audit trail (`audit_events`, `validation_events`, `restatement_events`, `ingestion_checkpoints`)
- metric engine (`metric_definitions` with 19 metrics, `metric_inputs`, `metric_calculation_runs`, `security_metric_snapshots`, `security_price_snapshots`, `screening_universe_memberships`)
- research workspace (`research_notes`, `investment_theses`, `saved_screeners`)

### Serving views (8 total)

- `company_research_summary_v`
- `company_latest_statement_facts_v`
- `filing_timeline_v`
- `company_statement_history_v`
- `company_statement_items_v`
- `company_metric_snapshot_v`
- `company_data_quality_v`
- `screener_results_v`

### Worker jobs (6 total)

- `sync-sec-submissions` — fetch SEC EDGAR submissions, normalize filings
- `fetch-sec-filing-documents` — store immutable raw filing documents
- `sync-sec-companyfacts` — ingest XBRL companyfacts payload
- `parse-sec-companyfacts` — parse into statements (35 facts)
- `compute-company-metrics` — compute 19 metrics (tested on AAPL + MSFT)
- `sync-price-snapshots` — fetch quotes from Twelve Data API

### CI/CD (6 workflows)

- `deploy.yml` — Flutter Web → Vercel (push to main)
- `sec-submissions-sync.yml` — daily SEC filings sync
- `sec-filing-documents-sync.yml` — daily SEC document fetch
- `sec-companyfacts-sync-parse.yml` — daily companyfacts sync + parse
- `recompute-metrics.yml` — manual metrics recompute
- `sync-price-snapshots.yml` — weekday price sync

### Test coverage

- `compute-company-metrics` tested end-to-end on AAPL and MSFT
- Full pipeline: sync → companyfacts → parse → compute
- 11 statement-only metrics computed correctly
- 7 price-dependent metrics correctly marked missing_input

## What Is Still Incomplete (Intentionally Deferred)

### Data/model work

- broader taxonomy mapping (currently 35 facts, full XBRL has thousands)
- sector/industry normalization tables
- `raw_financials`, `raw_macro`, `raw_ownership` tables
- FRED, Bank Indonesia, BPS integrations
- IDX issuer/reference data
- home market preference model
- `coverage_lists` table
- `recalculation_runs` table
- data quality scoring model
- screener filter execution worker

### Operational

- price data backfill (API credits need reset)
- metrics recompute after price data available
- key rotation, secret scan (pre-launch)

## Important Interpretation Rule

If another model says:

- "the app is missing company pages"
- "the app lacks research UI"
- "the schema is incomplete for valuation surfaces"

that may be true descriptively, but it is not automatically a useful critique.

The correct question is:

- is that gap intentional because backend foundation sequencing is still underway?

For most gaps listed above, the answer is yes — they are intentionally deferred.

## Recommended Mental Model

Current repo state:

1. Flutter shell and research pages are built.
2. Data foundation and serving views are complete.
3. Metric engine is working.
4. Remaining gaps are intentionally deferred to later phases.

Do not treat deferred items as defects.

## Source Docs

1. `docs/research-platform-execution-checklist.md`
2. `docs/research-platform-schema-implementation-plan.md`
3. `docs/sec-filings-foundation-checklist.md`
4. `docs/research-platform-ingestion-topology.md`
5. `docs/research-platform-gap-analysis.md`
