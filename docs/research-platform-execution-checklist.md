# Taug Research Platform Execution Checklist

Last updated: 2026-06-19

## Purpose

This checklist is intended for humans and AI agents.

It records:

- what has already been built
- what should be preserved
- what should be frozen
- what is not started
- what must happen next

Use this file as the first source of truth before planning or implementing anything.

Docs discipline for this repo:

- before every commit, sync the relevant `docs/` artifact first
- if status changed, update this checklist before committing

## Status Legend

- `[done]` implemented and committed
- `[partial]` exists, but not suitable as final architecture
- `[todo]` not started
- `[defer]` intentionally postponed
- `[stop]` should not be expanded in current architecture

## A. Current Product State

### App shell and user workspace

- `[done]` auth flow
- `[done]` compact terminal shell and tab navigation
- `[done]` watchlists
- `[done]` portfolios
- `[done]` settings page
- `[done]` compact design system pass

### Market monitoring features

- `[done]` quote snapshot cache
- `[done]` delayed charting
- `[done]` line chart default
- `[done]` top movers page
- `[done]` terminal brief landing page

### Context feeds

- `[done]` news aggregation feed
- `[done]` policy feed page
- `[done]` economic calendar page
- `[done]` provenance/source badges
- `[done]` basic freshness and source metadata

### UI fixes already shipped

- `[done]` startup hardening for web
- `[done]` policy feed dedupe
- `[done]` policy card fixed-height no-overflow layout
- `[done]` 12px baseline grid normalization

## B. Public Repo Hygiene

- `[done]` `.env` ignored
- `[done]` generated `app_env.g.dart` ignored
- `[done]` `app_env.g.dart` removed from full local history
- `[todo]` rotate any key that may have been used when old generated env file existed
- `[todo]` final pre-public secret scan before first remote push

## C. Product Direction Decisions

- `[done]` terminal-only roadmap challenged
- `[done]` pivot recommendation documented
- `[done]` product reframed toward research platform / investment research workspace
- `[todo]` final naming decision:
  - financial research platform
  - investment research workspace
  - research terminal

## D. What Must Be Frozen

- `[stop]` do not expand order book / running trades as strategic feature
- `[stop]` do not add AI/chatbot/LLM features
- `[stop]` do not build screener UI on current schema
- `[stop]` do not add more terminal-first features before data spine redesign
- `[stop]` do not make Supabase Edge Functions the long-term ETL engine

## E. Existing Architecture To Preserve

- `[done]` Flutter shell can be preserved
- `[done]` Supabase auth and RLS can be preserved
- `[done]` watchlist and portfolio user data can be preserved
- `[done]` compact design system can be preserved
- `[partial]` `symbols` and `exchanges` can serve as temporary seed reference data

## F. Critical Missing Foundations

### Core entities

- `[done]` `companies`
- `[done]` `securities`
- `[done]` `currencies`
- `[done]` `reporting_periods`
- `[todo]` sector and industry normalization tables

### Raw immutable layer

- `[done]` `raw_sources`
- `[done]` `raw_documents`
- `[done]` SEC raw filing document ingestion path
- `[done]` SEC raw companyfacts ingestion path
- `[todo]` `raw_financials`
- `[todo]` `raw_macro`
- `[todo]` `raw_ownership`

### Filing and statement layer

- `[done]` `filings`
- `[done]` `filing_versions`
- `[done]` `financial_statements`
- `[done]` `financial_statement_items`
- `[todo]` taxonomy mapping strategy

### Restatement support

- `[done]` `filing_version`
- `[done]` `statement_version`
- `[done]` `is_restated`
- `[done]` `supersedes`
- `[done]` `superseded_by`

### Research workflow layer

- `[todo]` `research_notes`
- `[todo]` `investment_theses`
- `[todo]` `saved_screeners`
- `[todo]` `coverage_lists`

### Audit and quality layer

- `[done]` `audit_events`
- `[done]` `validation_events`
- `[done]` `ingestion_checkpoints`
- `[todo]` `recalculation_runs`
- `[done]` `restatement_events`
- `[todo]` data quality scoring model

## G. User Preference Gaps

- `[partial]` user settings currently support timezone, density mode, default interval, default exchange, portfolio currency
- `[todo]` add separate `country`
- `[todo]` add separate `home_market`
- `[todo]` add separate `preferred_exchanges`
- `[todo]` add `base_currency`
- `[todo]` add dashboard/news/screener defaults tied to home market
- `[done]` home-market preference model documented in schema v2 design

## H. Data Source Plan

### Priority foundation sources

- `[done]` source strategy and ingestion priority documented
- `[todo]` SEC EDGAR ingestion worker
- `[todo]` FRED integration
- `[todo]` Bank Indonesia integration
- `[todo]` BPS integration
- `[todo]` IDX issuer/reference data review

### Secondary sources

- `[defer]` Nasdaq or exchange licensed datasets
- `[defer]` KSEI after access/licensing review
- `[defer]` IR website document fallbacks

### Explicitly avoid as foundation

- `[stop]` Yahoo Finance as core dependency
- `[stop]` undocumented scraping as main data backbone

## I. ETL / Worker Architecture

- `[done]` choose worker runtime:
  - Python preferred for filings and financial parsing
  - scheduled execution platform
- `[done]` define ingestion scheduler
- `[done]` choose GitHub Actions as MVP scheduler host
- `[done]` define raw payload retention rules
- `[done]` define parser versioning
- `[done]` define validation pipeline
- `[done]` define restatement detection process

## J. Screener Architecture

- `[done]` metric definition model
- `[done]` formula lineage design
- `[done]` point-in-time metric snapshot design
- `[done]` materialized screener read model
- `[done]` saved screener data model
- `[done]` screener filter DSL or normalized filter schema
- `[done]` MVP metric catalog documented

## K. Frontend Product Surfaces Needed Later

- `[todo]` company page
- `[todo]` security master page
- `[todo]` filings timeline page
- `[todo]` statement explorer
- `[todo]` ratio trend page
- `[todo]` valuation snapshot page
- `[todo]` screener page
- `[todo]` research notes page
- `[todo]` data quality and freshness surfaces

## L. Recommended Phase Order

### Phase 0: Freeze and document

- `[done]` pivot audit
- `[done]` gap analysis
- `[done]` execution checklist

Exit criteria:

- team agrees terminal expansion is frozen

### Phase 1: Schema v2 design

- `[done]` design target research schema
- `[done]` define raw / normalized / derived / research layers
- `[done]` define home-market preference model
- `[done]` define schema implementation plan

Exit criteria:

- schema review approved
- schema v2 document exists
- schema implementation plan exists

### Phase 2: Ingestion topology

- `[done]` choose worker runtime and deployment model
- `[done]` define raw document and payload storage layout
- `[done]` define validation and parser version conventions

Exit criteria:

- ingestion architecture approved
- ingestion topology document exists

### Phase 3: Filings foundation

- `[done]` document source strategy and priority order
- `[done]` define SEC filings foundation implementation checklist
- `[done]` create raw spine and audit spine migration
- `[done]` create canonical entity bridge migration for SEC attachment
- `[done]` scaffold Python worker and GitHub Actions SEC submissions workflow
- `[done]` implement SEC submissions ingestion path
- `[done]` implement SEC document fetch workflow and storage path
- `[done]` build filing and filing_version model
- `[done]` validate narrow-universe SEC smoke test locally
- `[done]` validate SEC rerun idempotency on repeated narrow-universe sync
- `[done]` validate partial-failure audit trail on mixed-result SEC sync
- `[done]` validate checkpoint advancement only after successful run
- `[done]` validate required SEC submissions keys before normalization
- `[done]` validate SEC submissions payload parse success separately from schema validation
- `[done]` validate SEC raw document hash and byte size before finalizing storage
- `[done]` validate duplicate detection rules for raw payload and raw document reuse
- `[done]` validate filing-to-canonical-company mapping during filing normalization
- `[done]` validate filing date and acceptance datetime sanity during filing normalization
- `[done]` validate filing-version linkage integrity during filing normalization
- `[done]` implement amendment supersession linking and restatement event emission for matched SEC filing candidates

Exit criteria:

- can trace filing document from database
- source strategy document exists
- SEC filings foundation checklist exists

### Phase 4: Statement normalization

- `[done]` create statement-layer schema foundation:
  - `currencies`
  - company-scoped `reporting_periods`
  - `statement_taxonomy_items`
  - `financial_statements`
  - `financial_statement_items`
- `[done]` implement SEC companyfacts raw-ingestion job with validation, audit trail, checkpointing, and duplicate detection
- `[todo]` parse and normalize company facts / statements
- `[todo]` support historical periods and statement versions
- `[todo]` support restatements

Exit criteria:

- can query historical statement items by entity and period

### Phase 5: Derived metrics and screener core

- `[done]` design formula engine
- `[done]` design metric snapshot/read model
- `[done]` design saved screener support
- `[todo]` implement formula engine
- `[todo]` implement metric snapshot/read model
- `[todo]` implement saved screener support

Exit criteria:

- screener queries are reproducible and explainable
- screener and metric engine design document exists

### Phase 6: Research workspace

- `[todo]` research notes
- `[todo]` thesis tracking
- `[todo]` company workspace UI
- `[todo]` quality/freshness indicator

Exit criteria:

- user can maintain an investment thesis on top of auditable data

## M. Agent Guardrails

Before any new implementation, the agent must ask:

1. Is this feature central to research workflow?
2. Does this require raw immutable data first?
3. Can the value be traced to a source and version?
4. Does this belong in Supabase, or in worker ETL?
5. Am I accidentally expanding the old terminal roadmap?
6. Have I synced the relevant `docs/` artifact before committing?

If the answer to question 5 is yes, stop and reassess.

If the answer to question 6 is no, sync docs first.
