# Taug SEC Filings Foundation Checklist

Last updated: 2026-06-19

## Purpose

This document turns the SEC foundation plan into an execution checklist.

It is the first phase-3 artifact intended to bridge planning into implementation.

The goal is not to build all of SEC support at once.

The goal is to reach the first trustworthy filing foundation that can:

- discover filings
- store raw filing artifacts immutably
- create filing lineage
- support later statement normalization

## Scope Boundary

This checklist covers:

- SEC submissions and filing metadata
- raw filing documents
- filing identity and version chain
- initial worker job definitions
- initial migration batches required for SEC

This checklist does not yet cover:

- full statement normalization
- full companyfacts parsing
- full screener metric computation
- historical backtesting

## Success Definition

Phase 3 SEC foundation is successful when:

1. A worker can discover new SEC filings for a target universe.
2. Raw SEC payloads are stored immutably.
3. Raw filing documents are stored immutably.
4. A filing can be traced from company to filing to filing version to raw document.
5. Amendments or changed filing packages create new versions instead of overwriting history.

## Target Initial Universe

Start narrow.

Recommended first universe:

- 25 to 100 large US companies

Reason:

- enough variety to validate architecture
- small enough to debug mapping and replay behavior

Do not start with the entire US listed universe.

## Phase-3 Workstreams

There are four workstreams:

1. SQL foundation
2. Worker foundation
3. SEC fetch and storage
4. Filing lineage validation

Current execution host choice:

- Python worker runs on GitHub Actions for MVP scheduling

## A. SQL Foundation Checklist

### A1. Raw ingestion tables

- `[done]` create `raw_sources`
- `[done]` create `raw_fetch_runs`
- `[done]` create `raw_documents`
- `[done]` create `raw_records`
- `[done]` create `raw_document_links`

Required notes:

- all raw tables must be additive
- no destructive migration in this batch

Exit criteria:

- worker has a place to write raw SEC payloads and document metadata

### A2. Audit and validation tables

- `[done]` create `audit_events`
- `[done]` create `validation_events`
- `[done]` create `restatement_events`

Exit criteria:

- worker failures and validation failures can be recorded in database

### A3. Filing lineage tables

- `[done]` create `filings`
- `[done]` create `filing_versions`

Required columns to verify:

- logical filing key
- filing type
- filing date
- acceptance datetime
- `raw_document_id`
- `raw_record_id`
- `parser_version`
- `supersedes_filing_version_id`
- `superseded_by_filing_version_id`
- `is_restated`

Exit criteria:

- one logical filing can have many versions without overwriting old history

### A4. Canonical entity prerequisites

- `[done]` create minimal `companies`
- `[done]` create minimal `securities`
- `[done]` create minimal `security_identifiers`

Required minimum SEC mapping support:

- internal `company_id`
- CIK mapping
- ticker mapping where available

Exit criteria:

- SEC filing can be attached to a canonical company entity

## B. Worker Foundation Checklist

### B1. Worker project bootstrap

- `[done]` create Python worker project
- `[done]` define module layout:
  - `sources/sec/`
  - `jobs/`
  - `storage/`
  - `validators/`
  - `audit/`
- `[done]` define environment variable contract
- `[done]` define worker versioning convention

Exit criteria:

- worker repo or worker directory can run one explicit SEC job end-to-end

### B2. Job registry and scheduler contract

- `[done]` define `filing_discovery` job
- `[done]` define `document_fetch` job
- `[done]` define retry policy
- `[done]` define checkpoint storage approach
- `[done]` implement database-backed checkpoint storage

Checkpoint examples:

- last CIK processed
- last accession processed
- last successful SEC submissions fetch timestamp

Exit criteria:

- job scope and idempotency rules are explicit

### B3. Supabase integration contract

- `[done]` define write path from worker to Postgres
- `[done]` define write path from worker to Storage
- `[done]` define service-role credential handling
- `[done]` define timeout and retry behavior for DB/storage writes

Exit criteria:

- worker can write raw rows and document metadata reliably

## C. SEC Fetch and Storage Checklist

### C1. Source metadata seed

- `[done]` insert `raw_sources` row for `sec_edgar`
- `[done]` document licensing/access notes in source metadata
- `[done]` mark source as official

Exit criteria:

- SEC becomes an explicit source in lineage model

### C2. Submissions fetch

- `[done]` fetch SEC submissions payload for target universe
- `[done]` store each submissions payload in `raw_records`
- `[done]` hash payloads
- `[done]` link records to `raw_fetch_runs`

Required rule:

- raw payload should be stored before normalization

Exit criteria:

- submissions payload is replayable from database

### C3. Filing discovery normalization

- `[done]` extract filing metadata from raw submissions payload
- `[done]` create logical `filings`
- `[done]` create first `filing_versions`
- `[done]` preserve source accession keys
- `[done]` cap per-run normalization volume for narrow-universe MVP execution

Exit criteria:

- discovered SEC filings exist as normalized logical filings

### C4. Raw document fetch

- `[done]` resolve document URLs for target filing package
- `[done]` download primary filing documents
- `[done]` store immutable files in Storage
- `[done]` record `content_hash`
- `[done]` create `raw_documents`
- `[done]` link `raw_documents` to related `raw_records`

Suggested initial document scope:

- primary filing document
- XBRL instance when available
- filing package metadata document

Exit criteria:

- at least one filing can be traced to its stored raw document

Validation note:

- local smoke test on `2026-06-19` succeeded with `1` target CIK, `3` normalized filings, and `1` stored primary filing document linked back to `raw_record` and `filing_version`

## D. Filing Versioning Checklist

### D1. Version identity rule

- `[done]` define what makes one logical filing unique
- `[todo]` define what creates a new filing version

Recommended signals:

- accession number
- changed package hash
- amendment type
- changed raw document hash

Exit criteria:

- worker can decide insert-new-version vs no-op deterministically

### D2. Restatement and amendment handling

- `[todo]` detect amendment filings
- `[todo]` create new `filing_versions` for amendments
- `[todo]` connect supersession chain
- `[todo]` emit `restatement_events` or equivalent audit event

Exit criteria:

- amendment does not overwrite prior filing version

## E. Validation Checklist

### E1. Raw validation

- `[done]` validate payload parse success
- `[done]` validate required SEC keys exist
- `[done]` validate fetched document hash and byte size
- `[done]` validate duplicate detection rules

### E2. Normalization validation

- `[done]` validate filing mapped to canonical company
- `[done]` validate filing date and acceptance datetime sanity
- `[todo]` validate version linkage integrity

### E3. Operational validation

- `[done]` verify rerun is idempotent
- `[done]` verify partial failure leaves audit trail
- `[done]` verify checkpoint only moves after success

Exit criteria:

- rerunning the same SEC job does not create uncontrolled duplicates

Validation note:

- local rerun validation on `2026-06-19` for `1` repeated CIK and `3` filings produced `created_raw_records=0`, `created_filings=0`, and `created_filing_versions=0`
- local partial-failure validation on `2026-06-19` for `0000320193` plus bogus `0000000000` produced `raw_fetch_runs.status=partial`, `successful_cik_ids=["0000320193"]`, `failed_cik_ids=["0000000000"]`, and matching item-level + run-level audit events
- local checkpoint validation on `2026-06-19` produced one `ingestion_checkpoints` row for successful single-CIK scope and no new checkpoint row for later partial mixed-CIK scope
- local document-fetch checkpoint validation on `2026-06-19` produced a `document_fetch` checkpoint row after a successful `attempted_documents=1` run
- local SEC-key validation on `2026-06-19` confirmed invalid synthetic payloads emit deterministic failure codes and valid live `0000320193` submissions still complete successfully
- local parse validation on `2026-06-19` confirmed synthetic bad-JSON payloads emit `sec_submissions_payload_json_parse_failed`, synthetic wrong-root payloads emit `sec_submissions_payload_root_type_invalid`, and live `0000320193` submissions still complete successfully
- local raw-document integrity validation on `2026-06-19` confirmed synthetic invalid bodies emit deterministic integrity failure codes and live fetched documents store `content_hash`, `byte_size`, `verified_at`, and `sec_primary_document_integrity=passed`
- local duplicate-detection validation on `2026-06-19` confirmed live submissions reruns emit `sec_submissions_duplicate_detection=passed` and direct duplicate `raw_document` insertion returns the existing row with `created=False`
- local company-mapping validation on `2026-06-19` confirmed live `0000320193` filings emit `sec_filing_company_mapping=passed` with matching canonical `company_id`
- local temporal-sanity validation on `2026-06-19` confirmed synthetic bad values emit deterministic sanity failure codes and live `0000320193` filings emit `sec_filing_temporal_sanity=passed`

## F. Storage Convention Checklist

### F1. Raw record conventions

- `[done]` define `record_type` values for SEC:
  - `sec_submissions`
  - `sec_filing_index`
  - `sec_companyfacts` later
- `[done]` define `source_record_key` convention
- `[done]` define `source_entity_key` convention using CIK

### F2. Raw document path convention

- `[done]` define Storage path pattern

Recommended pattern:

- `raw/sec_edgar/{yyyy}/{mm}/{dd}/{document_id}`

### F3. Metadata conventions

- `[done]` define metadata fields stored on raw SEC documents
- `[done]` define metadata fields stored on raw SEC payload records

Recommended metadata examples:

- accession number
- filing type
- cik
- ticker
- acceptance datetime
- source URL

Exit criteria:

- all SEC artifacts follow one predictable storage and metadata convention

## G. First Migration Batch Order

The first SEC implementation should not start with statement tables.

Recommended order:

1. raw ingestion tables
2. audit and validation tables
3. minimal canonical company/security mapping tables
4. filing lineage tables
5. worker bootstrap
6. SEC submissions fetch job
7. raw document fetch job

Do not skip this order.

## H. First Worker Jobs

### Job 1: `sync_sec_submissions`

Purpose:

- fetch submissions metadata
- store raw payload
- normalize logical filings

Definition of done:

- one target company produces raw records and filings rows

### Job 2: `fetch_sec_filing_documents`

Purpose:

- fetch documents for discovered filings
- store immutable raw docs
- link docs to filing versions

Definition of done:

- one discovered filing can be opened from stored raw document path

### Job 3: `reconcile_sec_filing_versions`

Purpose:

- detect changed or amended filings
- insert new versions when necessary

Definition of done:

- amendment creates new version rather than overwrite

## I. Anti-Patterns To Avoid

Avoid:

- fetching SEC data straight into final statement tables
- skipping raw payload storage because it feels redundant
- using only ticker without CIK-aware mapping
- assuming one filing equals one immutable truth forever
- treating document storage as optional

## J. Phase-3 Exit Criteria

Phase 3 is complete only when all of the following are true:

1. SEC exists in `raw_sources`.
2. Worker can fetch and store submissions payloads.
3. Worker can store raw filing documents immutably.
4. `filings` and `filing_versions` are populated for target universe.
5. At least one amendment or changed package path is handled without destructive overwrite.
6. Audit and validation events exist for failure cases.

## K. Recommended Immediate Next Implementation Steps

1. Write first SQL migrations for raw spine and audit spine.
2. Write minimal canonical entity migrations needed for SEC attachment.
3. Scaffold Python worker project.
4. Implement `sync_sec_submissions`.
5. Implement `fetch_sec_filing_documents`.
6. Test on narrow SEC universe.

## Progress Sync Rule

Before implementing any of the above:

1. update this checklist if scope changes
2. update the execution checklist when status changes
3. then commit
