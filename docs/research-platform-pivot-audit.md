# Taug Research Platform Pivot Audit

Last updated: 2026-06-19

## Purpose

This document records the current state of the repository and evaluates whether the project can pivot from a market-monitoring terminal into a trustworthy financial research platform.

This is an audit document, not an implementation plan.

It is intended to prevent future agents from making incorrect assumptions about:

- what already exists
- what can be reused
- what is structurally wrong for the new vision
- what should not be expanded further

## Executive Summary

### Verdict

The pivot is feasible.

The current repository is not yet a financial research platform.

It is currently a compact financial terminal and market-monitoring app with:

- quote snapshots
- charting
- market movers
- watchlists
- portfolio tracking
- news aggregation
- policy feed aggregation
- economic calendar

The repository can be reused as:

- frontend shell
- auth and user workspace
- compact UI system
- source badge concepts
- initial reference-data base

The repository should not be treated as the final data architecture for the new product.

### Architectural Direction

The product should pivot away from:

- terminal-first mental model
- market headline prioritization as the main moat
- frontend-triggered refresh pipelines
- Supabase Edge Functions as primary ETL runtime

The product should move toward:

- investment research workspace
- auditable financial data platform
- immutable raw ingestion
- restatement-aware statement storage
- reproducible metrics
- screener-grade query model

## Current Product Shape

### What the app is today

Current app surfaces:

- `Brief`
- `Market`
- `Watchlist`
- `Portfolio`
- `Chart`
- `News`
- `Policy`
- `Calendar`
- `Settings`

These are implemented in Flutter under `lib/features/`.

### Current product bias

The current codebase still optimizes for:

- watchlist monitoring
- delayed quotes
- compact chart usage
- ranked news/policy summaries
- terminal-like layout

This is a valid monitoring product.

It is not yet a trustworthy company research platform.

## Audit Scope

This audit covers:

1. Flutter architecture
2. Supabase usage
3. Database schema
4. Data flow
5. Data lineage readiness
6. Research-workflow readiness
7. Source feasibility
8. Scaling and integrity risks

## Repository Evidence Reviewed

This audit was based on direct inspection of the current repository, especially:

- `pubspec.yaml`
- `README.md`
- `supabase/schema.sql`
- `supabase/migrations/20260619000100_add_market_data_provenance.sql`
- `supabase/migrations/20260619000300_add_policy_events.sql`
- `lib/core/schema/app_schema.dart`
- `lib/features/chart/data/chart_repository.dart`
- `lib/features/news/data/news_intelligence_repository.dart`
- `lib/features/brief/data/brief_repository.dart`
- `.github/workflows/deploy.yml`
- `docs/stocks-first-terminal-roadmap.md`

If future code changes materially alter those files, this audit must be reviewed before more architecture work proceeds.

## Flutter Architecture Audit

### Strengths

- Feature-first structure is clear and maintainable for UI development.
- The app has a consistent compact design system in `lib/core/theme/`.
- `signals` is lightweight and appropriate for dense web UI updates.
- The recent UI normalization pass produced a reasonably consistent shell.

### Weaknesses

- Domain layer is thin. Most meaningful behavior lives in repositories or UI.
- Repositories often combine fetching, refreshing, ranking, and presentation preparation.
- Product concepts still reflect terminal workflows rather than research workflows.
- No first-class research objects exist in Flutter yet:
  - research note
  - thesis
  - screener definition
  - company coverage workspace

### Reuse Recommendation

Keep:

- theme tokens
- layout shell
- auth flow
- watchlist and portfolio surfaces as secondary workspace features

Do not continue expanding:

- terminal-first pages as the center of the product
- chart-centric workflows
- order-book and running-trade surfaces as strategic features

## Supabase Usage Audit

### Current usage

Supabase is currently used for:

- auth
- PostgreSQL
- RLS
- storage-ready architecture
- Edge Functions

### Problem

Supabase Edge Functions are currently acting as mini ETL jobs.

Examples:

- `refresh-quote-snapshots`
- `refresh-news`
- `refresh-policy`
- `get-chart-data`
- `search-symbols`

This is acceptable for lightweight prototype ingestion, but not for a durable research-data platform.

### Why it is a problem

- ETL is tied too closely to request-time app behavior.
- Frontend repositories invoke refreshes directly before reads.
- Heavy backfills, restatement detection, document parsing, and validation will not fit this model cleanly.
- Audit trails and parser versioning will become awkward if ETL remains hidden inside request-path serverless functions.

### Recommendation

Supabase should remain focused on:

- storage
- querying
- authorization
- RLS
- user data
- materialized views
- RPC endpoints for read/query workflows

Heavy data workloads should move to external workers:

- Python workers
- scheduled jobs
- cron on VPS
- Cloud Run / Railway / Fly.io workers

## Database Schema Audit

### Current schema shape

Current schema is centered on:

- `exchanges`
- `symbols`
- `profiles`
- `watchlists`
- `watchlist_items`
- `price_history`
- `instrument_sources`
- `quote_snapshots`
- `news_articles`
- `policy_events`
- `econ_events`
- `alerts`
- `user_settings`
- `portfolio_holdings`

### Strengths

- Good early separation between:
  - market metadata
  - user data
  - cached event data
- `instrument_sources` and provenance additions are useful seeds.
- RLS is applied to user-owned tables appropriately.

### Structural mismatch with new vision

The schema does not yet support:

- immutable raw ingestion
- filing storage as first-class concept
- statement facts
- normalized company model
- research-grade metric reproducibility
- restatements
- filing lineage
- multi-version financial statements
- screener-grade derived data
- home market preferences

### Missing table families

The following table families are currently absent:

- `companies`
- `securities`
- `currencies`
- `reporting_periods`
- `raw_sources`
- `raw_filings`
- `raw_financials`
- `raw_macro`
- `raw_ownership`
- `filings`
- `filing_versions`
- `financial_statements`
- `financial_statement_items`
- `metric_definitions`
- `research_notes`
- `saved_screeners`
- `investment_theses`
- `audit_events`
- `validation_events`
- `restatement_events`

### Important conclusion

The current schema is suitable for a monitoring terminal.

It is not suitable as the final schema for a research platform.

## Data Flow Audit

### Current pattern

Typical flow today:

1. Frontend calls repository
2. Repository may invoke a refresh function
3. Refresh function fetches vendor/public feed
4. Data is normalized inside function
5. Data is written directly into serving tables
6. Frontend reads serving tables

### Risks

- No immutable raw layer
- No parser version trace
- No replayable transformation chain
- No reliable restatement workflow
- No downstream validation checkpoint
- No separation between ingestion and serving models

### Recommendation

Desired pattern:

1. Worker fetches raw source
2. Raw payload stored immutably
3. Validation and parse stage writes normalized entities
4. Derived metrics computed downstream
5. Serving models and materialized views updated
6. Frontend reads serving layer only

## Data Lineage Audit

### Current state

Current lineage fields exist in some places:

- `source_label`
- `source_url`
- `latency_class`
- `is_official`
- `is_synthetic`
- `fetched_at`
- `as_of`

This is useful, but shallow.

### What is still missing

The platform cannot yet answer:

- which filing version produced a displayed value
- whether a value was reported or computed
- what formula generated a metric
- whether the displayed number came from raw fact or normalized item
- whether a value was superseded by a restatement
- which parser version processed the source

### Recommendation

All important values should eventually trace to:

- source
- document
- filing
- filing version
- parser version
- normalization version
- metric formula version

## Restatement Readiness Audit

### Current state

There is no restatement model today.

Missing required concepts:

- `filing_version`
- `statement_version`
- `is_restated`
- `supersedes`
- `superseded_by`

### Risk

If financial statements are added without these concepts, historical correctness will be broken early and expensively.

## Screener Readiness Audit

### Current state

The repository has no screener data model.

There is no infrastructure for:

- point-in-time financial metrics
- derived valuation metrics
- factor-based filtering
- historical metric snapshots
- reproducible formulas

### Conclusion

The current architecture cannot support a trustworthy screener yet.

Any screener built on the current schema would be superficial and difficult to audit.

## Research Workflow Audit

### Missing first-class research features

The following research artifacts do not exist yet:

- research notes
- thesis documents
- saved screeners
- coverage lists
- company workspaces
- data quality views
- freshness indicators tied to filings

### Current nearest equivalents

- `watchlists`
- `portfolio_holdings`
- `watchlist_items.notes`

These are useful but insufficient.

## Home Market Model Audit

### Current state

Current user data supports:

- timezone
- locale
- density mode
- default interval
- default exchange
- portfolio currency

This does not satisfy the required separation between:

- country
- home market
- preferred exchanges

### Recommendation

Add explicit user preference model later for:

- legal domicile country
- home market
- preferred exchanges array
- base currency
- default benchmark
- dashboard region priority

## Source Feasibility Assessment

### Global Sources

#### SEC EDGAR

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: low
- Coverage: high for US filings
- Maintenance burden: medium

Recommendation:

- Make this a primary foundation source
- Use submissions API and XBRL/companyfacts APIs
- Use bulk archives for scale

Reference:

- SEC EDGAR APIs: https://www.sec.gov/search-filings/edgar-application-programming-interfaces

#### FRED

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: low
- Coverage: macro only
- Maintenance burden: low

Recommendation:

- Use for macro context and release-linked datasets
- Do not confuse with company fundamentals source

Reference:

- FRED API: https://fred.stlouisfed.org/docs/api/fred/

#### Yahoo Finance

Assessment:

- Reliability: medium
- Sustainability: low
- Licensing risk: medium to high
- Coverage: broad
- Maintenance burden: high if scraped/undocumented

Recommendation:

- Do not use as foundation source
- Avoid building core product assumptions on Yahoo access

Reference:

- Yahoo Terms: https://legal.yahoo.com/us/en/yahoo/terms/otos/index.html

#### Stooq

Assessment:

- Reliability: medium
- Sustainability: medium
- Licensing risk: medium
- Coverage: useful but limited for research-grade fundamentals
- Maintenance burden: medium

Recommendation:

- Acceptable only as secondary or prototype reference feed

#### Nasdaq / exchange datasets

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: usually contractual
- Coverage: strong
- Maintenance burden: medium

Recommendation:

- Good later-stage upgrade path
- Not MVP foundation unless budget supports it

#### Investor Relations websites

Assessment:

- Reliability: medium
- Sustainability: medium
- Licensing risk: medium
- Coverage: useful for documents
- Maintenance burden: high

Recommendation:

- Use as raw document fallback only
- Never use as primary structured data backbone

### Indonesia Sources

#### IDX

Assessment:

- Reliability: medium to high
- Sustainability: medium
- Licensing risk: must be verified carefully
- Coverage: critical for Indonesia equities
- Maintenance burden: medium

Recommendation:

- Important for Indonesia expansion
- Use official issuer/company data where permitted

#### OJK

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: low to medium depending on use
- Coverage: regulatory and market oversight
- Maintenance burden: medium

Recommendation:

- Good regulatory context source
- Important for trust layer, not enough alone for financial statements

#### Bank Indonesia

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: low
- Coverage: macro, rates, FX
- Maintenance burden: low

Recommendation:

- Strong macro source for Indonesia home-market users

#### BPS

Assessment:

- Reliability: high
- Sustainability: high
- Licensing risk: low to medium depending on ToU
- Coverage: official statistics and macro
- Maintenance burden: low to medium

Recommendation:

- Strong macro/statistics source
- Worth integrating for Indonesia macro layer

Reference:

- BPS site and API links: https://www.bps.go.id/en

#### KSEI

Assessment:

- Reliability: potentially strong
- Sustainability: unknown until access terms confirmed
- Licensing risk: medium
- Coverage: ownership/shareholder-useful data
- Maintenance burden: medium

Recommendation:

- Verify access and licensing before depending on it

#### Company annual and quarterly reports

Assessment:

- Reliability: high as primary documents
- Sustainability: high
- Licensing risk: low for storage/processing if compliant
- Coverage: essential
- Maintenance burden: medium to high

Recommendation:

- Mandatory for Indonesia pathway
- Store immutably
- Parse downstream
- Version parsers explicitly

## Cost and Scaling Risk Assessment

### Current likely strengths

- Supabase is sufficient for current quote/news/calendar scale
- Flutter web shell is lightweight enough for current product size

### Future bottlenecks under new vision

- filing document storage growth
- parsed fact volume growth
- historical metric storage growth
- screener query latency
- recomputation costs after restatements
- vendor lock-in if all ETL remains inside Supabase function runtime

### Migration triggers

Move beyond current model when:

- filings reach thousands of documents
- statement item rows reach millions
- screener queries must run across multi-market equity universes
- restatement recomputation becomes common
- ETL execution time exceeds serverless comfort zone

## Strategic Recommendations

1. Freeze terminal-only feature expansion.
2. Reposition product internally as an investment research workspace.
3. Keep Supabase as serving/auth layer, not the main ETL engine.
4. Design raw immutable ingestion before adding statement features.
5. Build company and filing model before screener work.
6. Treat charts, movers, and ranked headlines as supporting context only.

## Implementation Rule For Future Agents

Do not start rewriting UI first.

Do not build screener first.

Do not add AI first.

Do not add financial statement pages before raw ingestion and lineage model exist.

The next correct work after this audit is:

1. gap analysis
2. target schema design
3. phased execution checklist
