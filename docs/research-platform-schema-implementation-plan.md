# Taug Research Platform Schema Implementation Plan

Last updated: 2026-06-19

## Purpose

This document translates schema v2 into an implementation sequence that can be executed safely.

It is not the SQL itself.

It is the migration order, dependency map, and cutover plan.

The main goal is to avoid a common failure mode:

- adding many new tables
- leaving old tables active without transition rules
- creating duplicate meanings for the same business concept
- cutting over UI before lineage and worker flows are real

## Current Starting Point

The current `taug` schema is still centered on:

- `exchanges`
- `symbols`
- `price_history`
- `quote_snapshots`
- `news_articles`
- `policy_events`
- `econ_events`
- `watchlists`
- `watchlist_items`
- `portfolio_holdings`
- `user_settings`

This is a serving schema for a compact monitoring app.

It is not yet a research-platform system-of-record schema.

## Implementation Principles

1. Add before cutover.
2. Backfill before switching reads.
3. Never overwrite historical truth.
4. Keep old serving tables alive until replacement read models are proven.
5. Do not start statement UI cutover before filing lineage exists.
6. Do not start screener UI cutover before metric snapshots exist.
7. Every migration batch must have explicit exit criteria.

## Migration Strategy Summary

The safest sequence is:

1. Foundation dimensions
2. Canonical entity model
3. Raw ingestion spine
4. Filing and statement lineage model
5. Derived metric and screener model
6. Research workspace extensions
7. Serving views and cutover
8. Legacy table demotion

This order matters.

If the project tries to implement statements before raw lineage, the platform will look complete while being structurally untrustworthy.

## Batch 0: Pre-Migration Controls

Purpose:

- define safety rails before SQL changes

Required outputs:

- migration naming convention
- rollback expectation per batch
- schema review checklist
- docs sync rule before commit

Required decisions:

- use additive migrations first
- forbid destructive drops during early v2 rollout
- keep current app functional during v2 table introduction

Exit criteria:

- team agrees old tables remain transitional until explicit cutover

## Batch 1: Foundation Dimensions

Purpose:

- introduce normalized dimensions with minimal disruption

Tables:

- `countries`
- `currencies`
- `sectors`
- `industries`
- `reporting_periods`

Current status:

- `currencies` implemented
- `reporting_periods` implemented as company-scoped to preserve issuer-relative fiscal calendars
- `countries`, `sectors`, and `industries` still pending

Changes to existing tables:

- prepare `exchanges` for later normalization

Notes:

- this batch should be low risk
- no user-facing cutover yet

Exit criteria:

- dimension tables exist
- seed strategy is defined
- exchange normalization fields are specified

## Batch 2: Canonical Entity Model

Purpose:

- separate company identity from security identity

Tables:

- `companies`
- `company_aliases`
- `company_relationships`
- `securities`
- `security_identifiers`

Bridge strategy:

- keep `symbols` alive
- treat `symbols` as transitional source for initial `securities` backfill

Critical rule:

- do not rename `symbols` into `securities`
- they do not represent the same maturity level of concept

Initial backfill approach:

- one `symbols` row becomes one provisional `securities` row
- create provisional `companies` rows where no canonical issuer model exists yet
- mark uncertain mappings with explicit status or metadata

Exit criteria:

- every active `symbols` row can map to a provisional `security_id`
- `company_id` to `security_id` relationship exists

## Batch 3: User Data Bridge

Purpose:

- prevent user-owned tables from blocking the entity-model transition

Affected tables:

- `watchlist_items`
- `portfolio_holdings`
- possibly `alerts`
- possibly `notes` fields embedded in old tables

Recommended change:

- add nullable `security_id` beside legacy `symbol_id`
- backfill `security_id`
- update app reads/writes later to prefer `security_id`

Why:

- user data should migrate by bridge fields first, not big-bang rewrite

Exit criteria:

- user-owned rows can resolve to `security_id`
- legacy `symbol_id` remains temporarily available

## Batch 4: Raw Ingestion Spine

Purpose:

- create the immutable ingestion backbone before statement parsing

Tables:

- `raw_sources`
- `raw_fetch_runs`
- `raw_documents`
- `raw_records`
- `raw_document_links`

Do not postpone this batch.

Without it:

- filing lineage will be fake
- backfills will not be replayable
- parser versioning will have nowhere reliable to attach

Exit criteria:

- worker can write immutable raw rows
- source metadata exists
- fetch runs are auditable

## Batch 5: Audit and Validation Spine

Purpose:

- make data quality and failure handling first-class

Tables:

- `audit_events`
- `validation_events`

Optional now, but strongly preferred in same batch or immediately after:

- `restatement_events`
- `data_quality_scores`

Rule:

- do not hide validation in worker logs only

Exit criteria:

- worker failures and validation failures can be queried from database

## Batch 6: Filing Lineage Model

Purpose:

- establish logical filing identity and version chain

Tables:

- `filings`
- `filing_versions`

Dependencies:

- requires raw spine
- requires canonical company model

Key constraints:

- unique filing key per source/logical filing
- self-reference chain for supersession
- parser version stored on filing version

Do not move to statement normalization before this batch is stable.

Exit criteria:

- one filing can have multiple versions
- version lineage is queryable
- raw document to filing-version trace exists

## Batch 7: Statement Taxonomy and Statement Headers

Purpose:

- create stable statement structure before fact-level scale arrives

Tables:

- `statement_taxonomy_items`
- `financial_statements`

Dependencies:

- filing lineage batch complete
- reporting periods available
- currencies available

Current status:

- schema foundation for `statement_taxonomy_items`, `financial_statements`, and `financial_statement_items` is implemented
- raw `sec_companyfacts` ingestion with validation, audit trail, checkpointing, and duplicate detection is implemented
- SEC companyfacts parser MVP is implemented for a curated core-fact catalog and official `10-K` / `10-Q` forms
- parser replay path now uses bulk active-version lookup, preloaded period/statement caches, and batched statement-item inserts
- statement-level supersession logic is implemented for amendment-backed statement matches
- parser and taxonomy mapping workflow still need broader coverage and possibly non-REST bulk writes before large-scale backfill

Rule:

- normalize statement headers before flooding the system with item rows

Exit criteria:

- filing version can produce one or more statement headers
- statement version chain is representable

## Batch 8: Statement Fact Table

Purpose:

- store actual reported facts in a narrow, traceable model

Tables:

- `financial_statement_items`

Required columns to lock early:

- lineage pointer
- taxonomy item pointer
- reported/calculated flag
- numeric and text support
- unit and scale

Index considerations:

- `financial_statement_id`
- `taxonomy_item_id`
- period/company access paths through joins

Do not over-normalize too early, but do not allow unstructured blobs here.

Exit criteria:

- historical fact queries work by company, statement type, and reporting period
- reported facts remain traceable to filing version

## Batch 9: Ownership and Relationship Extensions

Purpose:

- cover major-shareholder and group-structure requirements

Tables:

- `ownership_snapshots`

Optional later extensions:

- management people table
- board roles
- competitor relationship table

Exit criteria:

- ownership freshness can be represented

## Batch 10: Derived Metrics Spine

Purpose:

- support reproducible screener and valuation reads

Tables:

- `metric_definitions`
- `metric_inputs`
- `metric_calculation_runs`
- `security_metric_snapshots`
- `security_price_snapshots`
- `screening_universe_memberships`

Current status:

- all 6 tables implemented
- `metric_definitions` seeded with 19 MVP metrics across valuation, profitability, leverage, cash flow, scale, and growth categories
- formula engine worker job implemented (`compute-company-metrics`)
- `security_price_snapshots` still empty (price data integration pending)

Critical rule:

- do not build screener directly on raw statement tables alone
- the product needs fast serving snapshots with formula lineage

Exit criteria:

- metric outputs can be recalculated
- screener reads can run on serving snapshots

## Batch 11: Research Workspace Extensions

Purpose:

- support actual research workflow on top of auditable data

Tables:

- `coverage_lists`
- `coverage_list_items`
- `research_notes`
- `investment_theses`
- `saved_screeners`

RLS:

- required from day one on all user-owned tables

Exit criteria:

- workspace model supports thesis, notes, and saved screener flows

## Batch 12: Home Market Preference Model

Purpose:

- support dashboard and screener defaults without conflating country and market

Preferred implementation:

- extend `user_settings` or add dedicated preference table

Required fields:

- `country_code`
- `home_market_code`
- `preferred_exchange_codes`
- `base_currency_code`
- `benchmark_security_id`
- `news_priority_regions`

Rule:

- this can be implemented before or after research workspace tables
- it should be complete before dashboard refactor

Exit criteria:

- one user can be `country = ID`, `home_market = US`, `preferred_exchanges = [NASDAQ, NYSE]`

## Batch 13: Serving Views and Read Models

Purpose:

- give Flutter stable read surfaces without exposing internal pipeline complexity

Expected outputs:

- company summary views
- filing timeline views
- statement explorer views
- valuation snapshot views
- screener read views
- freshness and quality views

Current status:

- `company_research_summary_v` implemented
- `company_latest_statement_facts_v` implemented
- `filing_timeline_v` implemented
- `company_statement_history_v` implemented
- `company_statement_items_v` implemented
- `company_metric_snapshot_v` implemented
- `company_data_quality_v` implemented
- `screener_results_v` implemented
- `saved_screeners` table with RLS implemented

Rule:

- UI should read serving views or RPC read endpoints
- UI should not depend directly on every low-level base table

Exit criteria:

- first research UI can read only from v2-serving surfaces

## Batch 14: Legacy Table Demotion

Purpose:

- reduce ambiguity after new read model proves itself

Legacy tables likely to be demoted:

- `symbols`
- `price_history`
- `quote_snapshots`
- `news_articles`
- `policy_events`
- `econ_events`

Demotion means:

- no longer system of record
- possibly still used as serving cache or context feed
- clearly documented as secondary support tables

Do not drop them early.

Some may remain useful indefinitely as context-serving tables.

Exit criteria:

- no core research workflow depends on legacy assumptions

## Old-to-New Mapping

### Directly reusable with minimal change

- `profiles` -> keep
- `watchlists` -> keep
- `user_settings` -> keep and extend

### Requires bridge migration

- `watchlist_items.symbol_id` -> bridge to `security_id`
- `portfolio_holdings.symbol_id` or equivalent -> bridge to `security_id`
- `alerts` tied to old symbol identity -> bridge later

### Evolve, do not discard immediately

- `exchanges` -> evolve into normalized exchange master

### Transitional only

- `symbols` -> provisional feed into `securities`
- `price_history` -> transitional price serving store
- `quote_snapshots` -> transitional snapshot store
- `news_articles` -> context layer only
- `policy_events` -> context layer only
- `econ_events` -> context layer only

## Cutover Rules

### Rule 1

Do not cut Flutter watchlist or portfolio to `security_id` until:

- bridge fields are filled
- reads can resolve consistently
- symbol-to-security gaps are measured

### Rule 2

Do not build filing timeline UI until:

- `filings`
- `filing_versions`
- raw document trace

all exist together.

### Rule 3

Do not build statement explorer UI until:

- statement headers
- statement items
- taxonomy mapping
- reporting periods

all exist together.

### Rule 4

Do not build screener UI until:

- metric definitions
- metric snapshots
- screening universe
- freshness rules

all exist together.

## Recommended Migration Packaging

Keep migrations small and concern-specific.

Good examples:

- one migration for dimensions
- one migration for companies and securities
- one migration for raw ingestion tables
- one migration for filing lineage
- one migration for statement headers
- one migration for statement facts
- one migration for metric engine tables

Avoid:

- one giant migration with every v2 table

Reason:

- review quality collapses
- rollback confidence drops
- debugging becomes unclear

## SQL Review Checklist

Before any schema migration is merged, verify:

1. Does this create a duplicate meaning of an existing concept?
2. Is lineage represented explicitly?
3. Are restatement chains representable?
4. Is RLS applied where data is user-owned?
5. Are transitional bridge columns documented?
6. Does this force early cutover before workers exist?
7. Is the migration additive unless a later cutover explicitly allows otherwise?

## What This Plan Does Not Authorize Yet

This plan does not mean:

- the SQL is already approved
- the worker code is already designed in enough detail
- the Flutter UI should start using v2 entities immediately

It only means:

- the order of implementation is now constrained

## Progress Sync Rule

Before every commit from this point onward:

1. update the relevant document in `docs/`
2. reflect status changes in the execution checklist when applicable
3. only then create the commit

This is mandatory for this repo so future agents do not hallucinate project state.

## Next Correct Artifact

After this implementation plan, the next best planning artifact is:

- screener and metric engine design

That document should define:

- metric catalog for MVP
- formula lineage model
- point-in-time rules
- stale-input handling
- screener query model
