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

Taug is not currently being optimized for frontend feature completeness.

Taug is intentionally in a foundation-first phase.

That means:

- Flutter product surfaces are intentionally incomplete
- missing company pages and research screens are expected
- backend/data work is the current priority
- absence of research UI is not, by itself, a product defect

Do not misclassify planned-but-unbuilt Flutter surfaces as architectural failure.

## Product Direction

Taug is no longer being treated as a Bloomberg-terminal clone.

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

### Flutter / user workspace

- auth flow
- compact shell and navigation
- watchlists
- portfolios
- settings
- compact design system pass
- startup hardening and UI normalization

These are preserved, not the current bottleneck.

### Data foundation already implemented

- canonical `companies`
- canonical `securities`
- `security_identifiers`
- `currencies`
- company-scoped `reporting_periods`
- immutable raw ingestion spine
- SEC filing lineage
- filing version restatement chain
- statement layer schema
- SEC raw companyfacts ingestion
- SEC companyfacts parser MVP (35 XBRL concepts)
- parser replay hardening
- first research serving views
- metric engine schema (`metric_definitions` with 19 MVP metrics, `security_metric_snapshots`, `security_price_snapshots`, `screening_universe_memberships`)

### Serving views already implemented

- `company_research_summary_v`
- `company_latest_statement_facts_v`
- `filing_timeline_v`
- `company_statement_history_v`
- `company_statement_items_v`
- `company_metric_snapshot_v`
- `company_data_quality_v`
- `screener_results_v`

### What still needs implementation

- company page: company selector (currently loads first company only)
- price data integration into `security_price_snapshots` (enables valuation metrics)
- screener filter execution in worker (apply user-defined filters on `screener_results_v`)
- statement explorer page (drill into individual line items)
- valuation snapshot page
- screener page
- Flutter research pages (notes, theses)

### Test coverage

- `compute-company-metrics` tested on AAPL and MSFT (full pipeline: sync → companyfacts → parse → compute)
- 11 statement-only metrics computed correctly for both companies
- 7 price-dependent metrics correctly marked missing_input (no price data yet)

These are the first Flutter-safe read surfaces for research pages.

## What Is Still Incomplete By Design

### Flutter research surfaces

- company page
- filing timeline page
- statement explorer page
- ratio trend page
- valuation snapshot page
- screener page
- freshness / quality surfaces

These are pending because the foundation was being laid first.

### Data/model work still incomplete

- broader taxonomy mapping
- broader fact catalog coverage
- live proof for statement-level amendment lineage on suitable periodic amendments
- valuation read models
- statement explorer read models
- quality scoring
- freshness scoring model
- screener execution read model implementation

## Important Interpretation Rule

If another model says:

- "the app is missing company pages"
- "the app lacks research UI"
- "the schema is incomplete for valuation surfaces"

that may be true descriptively, but it is not automatically a useful critique.

The correct question is:

- is that gap intentional because backend foundation sequencing is still underway?

For most Flutter research surfaces, the answer is yes.

## Recommended Mental Model

Current repo state:

1. Preserve the usable Flutter shell.
2. Build research-grade data spine.
3. Build serving/read models.
4. Only then move Flutter research pages onto those views.

Do not reverse that order.

## Current Best Next Steps

High priority:

1. statement explorer serving/read model
2. valuation snapshot serving/read model
3. quality and freshness read model
4. only then start Flutter company research pages on top of those surfaces

## Source Docs To Read Next

1. `docs/research-platform-execution-checklist.md`
2. `docs/research-platform-schema-implementation-plan.md`
3. `docs/sec-filings-foundation-checklist.md`
4. `docs/research-platform-ingestion-topology.md`
5. `docs/research-platform-gap-analysis.md`
