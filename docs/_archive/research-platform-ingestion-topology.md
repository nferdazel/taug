# Taug Research Platform Ingestion Topology

Last updated: 2026-06-19

## Purpose

This document defines how data should enter, move through, and be validated inside the research-platform architecture.

It exists to prevent a bad implementation pattern:

- frontend triggers refresh
- refresh function fetches vendor data
- function writes directly into serving tables
- frontend reads mixed raw/derived state

That pattern is acceptable for a prototype terminal.

It is not acceptable for a trustworthy research platform.

## Current Repo Constraint

The current repository still contains this prototype pattern.

Examples observed in repo:

- Supabase Edge Functions:
  - `refresh-quote-snapshots`
  - `refresh-news`
  - `refresh-policy`
  - `refresh-calendar`
  - `get-chart-data`
  - `get-price`
  - `search-symbols`
- Flutter repositories still trigger refresh-oriented behavior before reads
- `BriefRepository` currently refreshes quote snapshots as part of page loading

Conclusion:

- ingestion is still partly request-coupled
- serving tables are still doing too much
- the pivot requires moving ingestion responsibility outside the UI request path

## Architecture Goal

The target topology is:

1. External source
2. Worker fetch job
3. Raw immutable storage
4. Validation stage
5. Normalization stage
6. Derived metric stage
7. Serving views and materialized tables
8. Flutter read-only query layer

The frontend should read.

The frontend should not orchestrate ingestion.

## Runtime Decision

### Recommended split

- Python workers for filing ingestion, financial parsing, normalization, and derived metrics
- Supabase Edge Functions only for lightweight authenticated orchestration or bounded utility tasks
- GitHub Actions only for CI/CD, not primary data ingestion

### Why Python first

Python is the best default for:

- SEC/filing parsing
- XBRL processing
- tabular validation
- restatement detection
- backfill scripts
- data-quality scoring

It is not because Python is trendy.

It is because the workload is document-heavy, batch-heavy, and parsing-heavy.

### Why not Supabase Edge Functions as primary ETL

- execution model is too request-centric
- long-running backfills are awkward
- parser dependency depth will grow
- replayability and batch orchestration become messy
- worker state and retry visibility become weak

## Deployment Model

### MVP recommendation

Use one external worker service and one scheduler.

Suggested MVP stack:

- Python worker app
- scheduled execution on GitHub Actions
- Supabase Postgres as system of record
- Supabase Storage for raw documents initially

Current repo decision:

- MVP worker runs on scheduled or manually dispatched GitHub Actions workflows
- this is a transitional execution platform, not the preferred long-term worker host

### Preferred sequence

1. Start with a single Python worker codebase
2. Run it on GitHub Actions scheduled jobs first
3. Keep job types explicit
4. Split services only after volume or runtime requires it

Avoid early microservices.

The project does not need them yet.

Also avoid pretending GitHub Actions is the final batch platform.

It is acceptable for MVP execution, not for infinite scale.

## Job Categories

All ingestion work should be classified into explicit job types.

### `reference_sync`

Purpose:

- countries
- currencies
- exchanges
- security master seed updates

Frequency:

- daily or weekly

### `price_snapshot_sync`

Purpose:

- refresh delayed price snapshots for serving layers
- refresh screening price inputs

Frequency:

- intraday scheduled

### `macro_series_sync`

Purpose:

- FRED
- Bank Indonesia
- BPS
- other official macro series

Frequency:

- based on source cadence

### `news_context_sync`

Purpose:

- optional context feed refresh
- not moat-critical

Frequency:

- frequent, but lower architectural priority

### `filing_discovery`

Purpose:

- discover new filings
- detect amendments
- detect availability of new source packages/documents

Frequency:

- scheduled multiple times per day for active sources

### `document_fetch`

Purpose:

- download filing documents
- store immutable raw documents
- compute content hashes

### `statement_parse`

Purpose:

- parse raw filing facts
- map taxonomy items
- build statement layer rows

### `metric_recalculation`

Purpose:

- recompute affected metrics after new filing, correction, or formula change

### `quality_recompute`

Purpose:

- recompute quality scores
- refresh freshness indicators

## Pipeline Stages

## Stage 1: Fetch

Input:

- job definition
- source configuration
- checkpoint state

Output:

- `raw_fetch_runs`
- `raw_documents`
- `raw_records`

Rules:

- no normalization here beyond envelope metadata
- keep response or document as close to source as practical
- record worker version and request fingerprint

## Stage 2: Validate Raw

Checks:

- payload parse success
- schema expectations
- duplicate detection by hash or key
- missing required source keys
- impossible timestamps

Output:

- `validation_events`
- `audit_events`

Rule:

- failed validation should not silently disappear

## Stage 3: Normalize Master Data

Examples:

- map issuer to `companies`
- map listing to `securities`
- map identifiers to `security_identifiers`
- map exchange and currency references

Rule:

- preserve source keys for reverse tracing

## Stage 4: Normalize Filings and Statements

Examples:

- create `filings`
- create `filing_versions`
- create `financial_statements`
- create `financial_statement_items`

Rules:

- every normalized statement fact must reference filing lineage
- restatements insert new versions
- prior versions remain queryable

## Stage 5: Derive Metrics

Examples:

- PE
- PB
- PS
- EV/EBIT
- EV/EBITDA
- ROE
- ROIC
- debt/equity
- FCF margin

Outputs:

- `metric_calculation_runs`
- `security_metric_snapshots`

Rules:

- metric formula version must be stored
- enough input lineage must remain to reproduce the result

## Stage 6: Publish Serving Layer

Examples:

- screener views
- company summary views
- valuation snapshot views
- freshness and quality views

Rule:

- Flutter should query this layer
- Flutter should not read half-normalized staging rows

## Scheduling Model

### Recommended scheduler behavior

Every scheduled job should be:

- idempotent
- resumable
- bounded by explicit scope
- checkpointed

### Checkpoint examples

- last filing accession processed
- last macro observation date
- last price date per source/universe
- last successful document hash

### Minimum scheduler metadata

Track:

- job type
- job scope
- cadence
- last success
- last failure
- next run
- retry count

This can live in the worker app config first, then move to a database-backed scheduler table later if needed.

## Storage Conventions

### Raw document storage

Initial recommendation:

- store immutable documents in Supabase Storage
- path by source and date
- include stable IDs, not only filenames

Suggested path shape:

- `raw/sec_edgar/2026/06/19/{document_id}`
- `raw/idx/2026/06/19/{document_id}`

### Raw structured payload storage

Initial recommendation:

- store structured payloads in Postgres `raw_records`
- only move to object storage if payload volume becomes too large

### Migration trigger

Consider external object storage later when:

- document volume becomes materially large
- Supabase storage cost or egress becomes painful
- worker processing benefits from colocated object storage

Do not prematurely optimize this.

## Parser Versioning

Every parser that transforms raw data into normalized data must have an explicit version.

Store parser version on:

- `raw_fetch_runs.worker_version`
- `filing_versions.parser_version`
- `metric_calculation_runs.worker_version`

Rules:

- parser behavior changes must bump version
- recalculations triggered by parser changes should create audit events
- do not hide parse logic changes behind silent redeploys

## Validation Framework

Validation should happen at multiple stages.

### Raw validation

- payload shape
- required keys
- timestamp sanity
- duplicate hash detection

### Normalization validation

- issuer mapping success
- exchange and currency mapping success
- reporting period consistency
- statement balancing or sign sanity when applicable

### Derived metric validation

- division-by-zero handling
- missing dependency handling
- point-in-time correctness
- stale price vs fresh filing mismatch checks

### User-visible validation outputs

Expose later:

- freshness status
- quality score components
- missing data warnings
- stale source warnings

## Restatement Detection

Restatement handling must be explicit.

### Detection signals

- amendment filing types
- changed content hash
- changed filing accession payload
- changed reported values for same logical period

### Required outcomes

- insert new `filing_version`
- mark linkage through `supersedes` chain
- emit `restatement_events`
- trigger downstream metric recalculation

Rule:

- never update old statement rows in place to simulate history

## Retry and Failure Model

Every worker job needs structured failure handling.

### Retryable failures

- temporary source outage
- timeout
- rate limiting
- transient storage/network error

### Non-retryable failures

- permanent mapping error
- unsupported document type
- invalid credentials
- parser invariant violation requiring code change

### Required behavior

- store failure on `raw_fetch_runs` or downstream run table
- emit `audit_events`
- cap retries
- keep dead-letter visibility for manual follow-up

## Concurrency and Idempotency

Workers must be safe under overlap.

Required strategies:

- unique keys on source identifiers
- hash-based duplicate detection
- insert-or-ignore behavior where appropriate
- checkpoint updates only after successful commit

Do not rely on manual operator discipline.

The system should defend itself.

## Source Prioritization

### Phase 1 sources

- SEC EDGAR
- FRED
- Bank Indonesia
- BPS

Why:

- official
- sustainable
- architecture-defining

### Phase 2 sources

- IDX issuer and reference data
- company annual reports
- company quarterly reports

Why:

- critical for Indonesia expansion
- somewhat higher integration and maintenance burden

### Context-only sources

- news RSS
- policy feeds

Why:

- useful, but not the foundation of research correctness

### Avoid as core dependency

- Yahoo Finance
- undocumented scraping workflows

## Supabase Responsibilities After Pivot

Supabase should own:

- auth
- RLS
- Postgres storage
- Storage bucket for raw docs initially
- serving views
- RPC read/query endpoints
- user-owned research data

Supabase should not own:

- primary filing parsing runtime
- long-running backfills
- restatement orchestration
- heavy metric recomputation

## Flutter Responsibilities After Pivot

Flutter should:

- read serving views and query endpoints
- render research workflow surfaces
- store user inputs such as notes, watchlists, and saved screeners

Flutter should not:

- trigger core ingestion on page open
- calculate canonical financial metrics as source of truth
- be responsible for data freshness guarantees

## Repo-Specific Refactors Implied By This Document

These are not done yet, but they are now architecturally implied:

1. Remove refresh-before-read behavior from page repositories.
2. Demote current Edge Functions from ETL backbone to transitional utilities.
3. Move ranking and data-mix logic out of critical correctness paths.
4. Introduce worker-owned run tracking and audit event writes.
5. Add serving views for future company, filing, statement, and screener pages.

## Minimal MVP Worker Shape

One worker codebase is enough initially.

Suggested internal modules:

- `sources/`
- `jobs/`
- `storage/`
- `normalizers/`
- `parsers/`
- `metrics/`
- `validators/`
- `audit/`

Suggested first jobs:

1. `sync_sec_filings`
2. `fetch_sec_documents`
3. `parse_sec_companyfacts`
4. `sync_fred_series`
5. `recompute_metrics_for_company`

## Exit Criteria For Phase 2

Phase 2 is complete when:

1. Worker runtime is chosen.
2. Scheduler model is chosen.
3. Raw storage conventions are written.
4. Parser versioning rules are written.
5. Validation and retry model are written.
6. Supabase versus worker responsibility boundary is explicit.

This document is intended to satisfy that planning milestone.
