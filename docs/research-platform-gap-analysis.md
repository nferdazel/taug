# Taug Research Platform Gap Analysis

Last updated: 2026-06-19

## Purpose

This document translates the pivot audit into a practical gap map:

- what to keep
- what to rewrite
- what to deprioritize
- what is completely missing

Use this before implementation planning.

## Summary

### Current repository category

Current repository is best described as:

- compact market-monitoring app
- terminal-style quote/news workspace

### Target repository category

Target repository should become:

- investment research workspace
- financial research platform

### Main conclusion

The pivot is not a feature extension.

It is a data-model and ingestion-model correction.

## Keep / Rewrite / Deprioritize Matrix

### Keep

These components are useful and should survive the pivot with moderate adaptation.

#### Frontend shell

- auth flow
- route shell
- page layout structure
- compact design system
- status badge pattern

Why keep:

- UI shell is not the main blocker
- user workspace still needs watchlists, notes, and preferences

#### User-owned data patterns

- `profiles`
- `watchlists`
- `watchlist_items`
- `portfolio_holdings`
- `user_settings`

Why keep:

- these remain valid as research workspace primitives

#### Reference-data seeds

- `exchanges`
- `symbols` as temporary security master seed
- `instrument_sources`

Why keep:

- useful bootstrap material
- can be evolved into proper `securities` model later

### Rewrite

These components should not be expanded further in their current form.

#### Schema core

Rewrite from symbol-and-cache orientation toward:

- raw layer
- filing layer
- statement layer
- derived metric layer

Affected areas:

- `symbols`
- `price_history`
- `news_articles`
- `policy_events`
- `econ_events`

Reason:

- current tables are serving/cache tables, not research-grade system-of-record tables

#### ETL architecture

Rewrite from:

- frontend-triggered refresh
- Edge Function mini ETL

Toward:

- worker-driven ingestion
- immutable raw payload retention
- downstream normalization and validation

#### Metric logic

Rewrite from:

- client-side ranking and ad-hoc derived logic

Toward:

- formula definitions
- reproducible derived metrics
- point-in-time queryable outputs

### Deprioritize

These are not useless, but should not drive roadmap sequencing.

#### Terminal-first features

- order book
- running trades
- movers as primary landing logic
- chart customization as strategic work

Reason:

- they do not create the moat described by the new vision

#### News intelligence as moat

- ranked impact headlines
- policy impact scoring

Reason:

- useful context layer
- not the durable differentiator

### Missing Entirely

These capabilities do not exist and are essential.

#### Company and filing model

- `companies`
- `company_aliases`
- `securities`
- `security_identifiers`
- `reporting_periods`
- `filings`
- `filing_versions`

#### Raw immutable ingestion model

- `raw_sources`
- `raw_documents`
- `raw_filings`
- `raw_facts`
- `raw_macro`
- `raw_ownership`

#### Statement model

- `financial_statements`
- `financial_statement_items`
- statement taxonomy mapping
- parser version tracking

#### Research model

- `research_notes`
- `investment_theses`
- `saved_screeners`
- `coverage_lists`
- `company_bookmarks`

#### Audit and validation model

- `audit_events`
- `validation_events`
- `restatement_events`
- `recalculation_runs`

#### Preferences model for home market

- `country`
- `home_market`
- `preferred_exchanges`
- `base_currency`
- `benchmark_symbol`
- `news_priority_regions`

## Domain Gap Breakdown

### 1. Company Research

Current:

- basic symbol metadata only

Target:

- company entity
- multi-security support
- exchange mapping
- sector and industry normalization
- parent/subsidiary relationship support

Gap severity:

- critical

### 2. Financial Statements

Current:

- absent

Target:

- historical statements
- line items
- filing traceability
- restatement support

Gap severity:

- critical

### 3. Valuation Metrics

Current:

- absent

Target:

- reproducible formula engine
- snapshot outputs
- traceable inputs

Gap severity:

- critical

### 4. Screener

Current:

- absent

Target:

- efficient cross-security filtering
- materialized screening layer
- saved screener definitions

Gap severity:

- critical

### 5. Research Workflow

Current:

- watchlists and portfolio only

Target:

- notes
- theses
- workflow state
- bookmarks
- saved views

Gap severity:

- high

### 6. Macro Context

Current:

- economic calendar events
- policy feed events

Target:

- official series history
- macro indicators by home market
- freshness and quality scoring

Gap severity:

- medium

## Data Architecture Gap

### Current pattern

External source -> edge function -> serving table -> frontend

### Target pattern

External source -> raw immutable store -> normalized entities -> derived metrics -> serving views -> frontend

### Gap severity

- critical

## Operational Gap

### Missing operational systems

- parser versioning
- validation jobs
- import audit trail
- restatement detection
- backfill orchestration
- source health monitoring

## Product Surface Gap

### Surfaces to add eventually

- company profile page
- filing timeline
- financial statement explorer
- ratio trend explorer
- valuation snapshot
- screener builder
- research notes workspace
- data quality indicator
- freshness indicator

### Surfaces to demote

- `Brief` as strategic center
- `Market` as strategic center
- `Chart` as product center

## Recommended Reuse Strategy

### Keep as-is for now

- auth
- routing shell
- compact UI system
- watchlist
- portfolio

### Freeze

- `Brief`
- `Market`
- terminal-only enhancements
- news ranking expansion

### Build next

1. target schema v2
2. ingestion topology
3. research domain tables
4. company page skeleton
5. filings ingestion

## Do Not Do List

Do not:

- build AI features
- build sentiment features
- build recommendation engines
- scale terminal monitoring features further
- add screener UI before screener data model exists
- store every metric without reproducible formula lineage

## Bottom Line

If the goal is a trustworthy research platform, then:

- keep the shell
- keep user workspace features
- rebuild the data spine
- freeze terminal expansion

This is a controlled pivot, not a full discard.
