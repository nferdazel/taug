# Taug Research Platform Schema V2

Last updated: 2026-06-19

## Purpose

This document defines the target data model for the research-platform pivot.

It is not a migration file.

It is the architectural contract that future schema work must follow.

The goals are:

- preserve raw data immutably
- support traceable financial statements
- support restatements without destructive updates
- support reproducible derived metrics
- support screener-grade queries
- preserve user-owned research workflows

## Design Rules

1. Raw data is immutable.
2. Normalized data is derived from raw data, never the other way around.
3. Displayed values must be traceable to a source, version, and timestamp.
4. Restatements must create new versions, not overwrite old ones.
5. Derived metrics must be reproducible from stored formulas and inputs.
6. Supabase is the system of record for storage and query serving, not the heavy ETL runtime.
7. User-owned research data must remain isolated with RLS.

## Layer Model

The target model is split into five layers:

1. Raw layer
2. Normalized master-data layer
3. Filing and statement layer
4. Derived and screener layer
5. Research workspace layer

Cross-cutting concerns:

- auditability
- validation
- lineage
- freshness
- quality scoring

## 1. Raw Layer

Purpose:

- retain original source payloads
- retain original documents
- make parsing replayable
- make vendor/source changes auditable

### `raw_sources`

One row per upstream source configuration.

Suggested columns:

- `id`
- `code`
- `name`
- `source_type`
- `region`
- `is_official`
- `licensing_notes`
- `access_method`
- `default_latency_class`
- `active_from`
- `active_to`
- `created_at`
- `updated_at`

Notes:

- Examples: `sec_edgar`, `fred`, `idx`, `ojk`, `bank_indonesia`, `bps`
- This is metadata, not event storage

### `raw_fetch_runs`

One row per worker fetch execution.

Suggested columns:

- `id`
- `raw_source_id`
- `job_type`
- `job_scope`
- `started_at`
- `finished_at`
- `status`
- `request_fingerprint`
- `worker_version`
- `error_code`
- `error_message`
- `metadata`

Why:

- every import should trace to an execution run

### `raw_documents`

Immutable document registry.

Suggested columns:

- `id`
- `raw_source_id`
- `fetch_run_id`
- `document_type`
- `document_url`
- `storage_path`
- `mime_type`
- `content_hash`
- `byte_size`
- `published_at`
- `fetched_at`
- `verified_at`
- `metadata`

Why:

- annual reports, quarterly reports, XBRL files, HTML filings, PDF disclosures must be preserved

### `raw_records`

Immutable raw payload store for structured API or scraped responses.

Suggested columns:

- `id`
- `raw_source_id`
- `fetch_run_id`
- `record_type`
- `source_record_key`
- `source_entity_key`
- `observed_at`
- `effective_at`
- `payload_json`
- `payload_hash`
- `schema_version`
- `created_at`

Why:

- avoid creating many source-specific raw tables too early
- can later split into dedicated raw tables if scale demands it

### `raw_document_links`

Map raw structured records to raw documents.

Suggested columns:

- `id`
- `raw_record_id`
- `raw_document_id`
- `link_type`
- `created_at`

Why:

- one filing may include multiple source records and multiple stored documents

## 2. Normalized Master-Data Layer

Purpose:

- create canonical entities for company research
- separate company identity from tradeable securities
- support multi-exchange and multi-currency reality

### `countries`

Suggested columns:

- `id`
- `iso2`
- `iso3`
- `name`
- `region`

### `currencies`

Suggested columns:

- `id`
- `code`
- `name`
- `symbol`
- `minor_unit`
- `is_active`

### `exchanges`

Current table can evolve into this layer.

Required additions:

- canonical exchange identifiers
- `mic_code`
- `operating_country_id`
- `default_currency_id`
- `timezone`
- `is_primary_market`
- `is_active`

### `sectors`

Suggested columns:

- `id`
- `code`
- `name`
- `taxonomy`

### `industries`

Suggested columns:

- `id`
- `sector_id`
- `code`
- `name`
- `taxonomy`

### `companies`

Canonical business entity.

Suggested columns:

- `id`
- `legal_name`
- `display_name`
- `country_id`
- `domicile_country_id`
- `primary_sector_id`
- `primary_industry_id`
- `founded_on`
- `website_url`
- `description`
- `status`
- `created_at`
- `updated_at`

Important:

- one company can have multiple securities
- one security is not the same as one company

### `company_aliases`

Suggested columns:

- `id`
- `company_id`
- `alias`
- `alias_type`
- `source`

### `company_relationships`

Suggested columns:

- `id`
- `parent_company_id`
- `child_company_id`
- `relationship_type`
- `effective_from`
- `effective_to`
- `source_document_id`

Why:

- support parent, subsidiary, spin-off, merged entity mapping later

### `securities`

Canonical tradeable instrument.

Suggested columns:

- `id`
- `company_id`
- `exchange_id`
- `ticker`
- `name`
- `security_type`
- `currency_id`
- `is_primary_listing`
- `listed_on`
- `delisted_on`
- `status`
- `created_at`
- `updated_at`

### `security_identifiers`

Suggested columns:

- `id`
- `security_id`
- `identifier_type`
- `identifier_value`
- `effective_from`
- `effective_to`

Examples:

- CIK
- ISIN
- FIGI
- SEDOL
- local exchange identifiers

### `reporting_periods`

Canonical period dimension.

Important:

- reporting periods should be company-scoped, not globally shared
- fiscal year and quarter labels are issuer-relative
- global period labels without company context will create wrong joins later

Suggested columns:

- `id`
- `company_id`
- `fiscal_year`
- `fiscal_quarter`
- `period_type`
- `period_start`
- `period_end`
- `label`

Why:

- statements and metrics should point to normalized periods, not ad-hoc labels

## 3. Filing and Statement Layer

Purpose:

- store filing lineage
- preserve version chains
- represent reported statements with point-in-time correctness

### `filings`

One logical filing identity.

Suggested columns:

- `id`
- `company_id`
- `raw_source_id`
- `filing_type`
- `filing_key`
- `filing_date`
- `acceptance_datetime`
- `period_end`
- `fiscal_year`
- `fiscal_quarter`
- `is_amendment`
- `created_at`

### `filing_versions`

One row per version of a filing payload or parseable filing package.

Suggested columns:

- `id`
- `filing_id`
- `version_number`
- `raw_document_id`
- `raw_record_id`
- `parser_version`
- `is_restated`
- `supersedes_filing_version_id`
- `superseded_by_filing_version_id`
- `detected_at`
- `ingested_at`
- `status`
- `metadata`

Rule:

- never update old versions into the new truth
- always insert the next version

### `statement_taxonomy_items`

Canonical line-item dictionary.

Suggested columns:

- `id`
- `code`
- `name`
- `statement_type`
- `unit_type`
- `sign_convention`
- `taxonomy_source`
- `parent_taxonomy_item_id`
- `is_core`

Why:

- prevent fragile free-text line-item usage

### `financial_statements`

Statement header at versioned filing level.

Suggested columns:

- `id`
- `company_id`
- `security_id`
- `filing_id`
- `filing_version_id`
- `reporting_period_id`
- `statement_type`
- `statement_version`
- `currency_id`
- `period_start`
- `period_end`
- `published_at`
- `is_restated`
- `supersedes_statement_id`
- `superseded_by_statement_id`
- `last_reported_at`
- `last_fetched_at`
- `last_verified_at`

### `financial_statement_items`

Time-series fact table for reported items.

Suggested columns:

- `id`
- `financial_statement_id`
- `taxonomy_item_id`
- `lineage_source_type`
- `lineage_source_id`
- `value_numeric`
- `value_text`
- `unit`
- `scale`
- `decimals`
- `is_reported`
- `is_calculated`
- `confidence_score`
- `created_at`

Important:

- one row should be one reported fact
- keep it narrow and queryable
- do not store opaque blobs here

### `ownership_snapshots`

Suggested columns:

- `id`
- `company_id`
- `as_of_date`
- `owner_name`
- `owner_type`
- `ownership_percent`
- `source_document_id`
- `last_fetched_at`
- `last_verified_at`

Why:

- major shareholders and ownership freshness are product requirements

## 4. Derived and Screener Layer

Purpose:

- compute reproducible metrics
- support scalable screening across many securities
- preserve formula lineage

### `metric_definitions`

Canonical formula catalog.

Suggested columns:

- `id`
- `code`
- `name`
- `category`
- `description`
- `formula_expression`
- `formula_version`
- `unit_type`
- `is_point_in_time`
- `is_ttm`
- `is_active`
- `created_at`
- `updated_at`

Rule:

- no silent formula edits
- formula changes create a new `formula_version`

### `metric_inputs`

Optional explicit mapping for metric dependencies.

Suggested columns:

- `id`
- `metric_definition_id`
- `input_kind`
- `taxonomy_item_id`
- `dependency_metric_definition_id`
- `input_label`

Why:

- useful for explainability and recalculation planning

### `metric_calculation_runs`

One row per batch recomputation.

Suggested columns:

- `id`
- `run_type`
- `started_at`
- `finished_at`
- `status`
- `trigger_reason`
- `trigger_reference_type`
- `trigger_reference_id`
- `worker_version`
- `metadata`

### `security_metric_snapshots`

Serving layer for screener and ratio pages.

Suggested columns:

- `id`
- `security_id`
- `company_id`
- `metric_definition_id`
- `reporting_period_id`
- `as_of_date`
- `value_numeric`
- `currency_id`
- `calculation_run_id`
- `formula_version`
- `input_fingerprint`
- `last_reported_at`
- `last_fetched_at`
- `last_verified_at`

Rules:

- store outputs needed for fast filtering
- keep enough lineage to reproduce the number
- avoid materializing every imaginable metric unless it serves product queries

### `security_price_snapshots`

Suggested columns:

- `id`
- `security_id`
- `price_date`
- `close_price`
- `market_cap`
- `enterprise_value`
- `currency_id`
- `source_record_id`
- `last_fetched_at`
- `last_verified_at`

Why:

- screeners often combine fundamentals and price-dependent metrics

### `screening_universe_memberships`

Suggested columns:

- `id`
- `security_id`
- `universe_code`
- `effective_from`
- `effective_to`

Why:

- simplifies queries such as `US common stocks`, `IDX equities`, `active ADRs`

## 5. Research Workspace Layer

Purpose:

- give users durable research workflows on top of auditable data

### Preserve and adapt

Current user-owned tables that can stay with targeted migration:

- `profiles`
- `watchlists`
- `watchlist_items`
- `portfolio_holdings`
- `user_settings`

### `coverage_lists`

Suggested columns:

- `id`
- `user_id`
- `name`
- `description`
- `created_at`
- `updated_at`

### `coverage_list_items`

Suggested columns:

- `id`
- `coverage_list_id`
- `company_id`
- `security_id`
- `status`
- `priority`
- `created_at`

### `research_notes`

Suggested columns:

- `id`
- `user_id`
- `company_id`
- `security_id`
- `title`
- `body`
- `note_type`
- `created_at`
- `updated_at`

### `investment_theses`

Suggested columns:

- `id`
- `user_id`
- `company_id`
- `security_id`
- `title`
- `stance`
- `summary`
- `status`
- `opened_at`
- `closed_at`
- `created_at`
- `updated_at`

### `saved_screeners`

Suggested columns:

- `id`
- `user_id`
- `name`
- `description`
- `universe_code`
- `filter_definition`
- `sort_definition`
- `created_at`
- `updated_at`

Rule:

- store normalized filter schema, not ad-hoc prose

## Cross-Cutting Tables

## `audit_events`

Use for important system events.

Suggested columns:

- `id`
- `event_type`
- `entity_type`
- `entity_id`
- `severity`
- `occurred_at`
- `actor_type`
- `actor_id`
- `reference_type`
- `reference_id`
- `payload`

Examples:

- filing imported
- validation failed
- source payload changed
- restatement detected
- metric recalculated

## `validation_events`

Suggested columns:

- `id`
- `entity_type`
- `entity_id`
- `validation_rule`
- `status`
- `message`
- `detected_at`
- `resolved_at`
- `payload`

## `data_quality_scores`

Serving table for user-visible quality indicators.

Suggested columns:

- `id`
- `company_id`
- `security_id`
- `score_date`
- `overall_score`
- `historical_coverage_score`
- `completeness_score`
- `validation_score`
- `verification_score`
- `ownership_freshness_score`
- `restatement_support_score`
- `notes`

Why:

- the score should be explainable by component, not a magic number

## Home Market Preference Model

Do not overload `profiles`.

Prefer a dedicated settings model or extend `user_settings` with explicit columns for:

- `country_code`
- `home_market_code`
- `preferred_exchange_codes`
- `base_currency_code`
- `benchmark_security_id`
- `news_priority_regions`

Rules:

- `country` is legal or residential context
- `home_market` drives dashboard and macro defaults
- `preferred_exchanges` narrows workflow defaults without limiting access

Example:

- `country = ID`
- `home_market = US`
- `preferred_exchanges = [NASDAQ, NYSE]`

That combination must be valid.

## What Can Be Reused From Current Schema

Keep with migration/evolution:

- `profiles`
- `watchlists`
- `watchlist_items`
- `portfolio_holdings`
- `user_settings`
- `exchanges`

Keep only as temporary bridge:

- `symbols`
- `price_history`
- `quote_snapshots`
- `news_articles`
- `policy_events`
- `econ_events`
- `instrument_sources`

Reason:

- these are useful serving tables, but not sufficient as long-term research system-of-record tables

## What Should Not Exist As Final Architecture

Avoid these anti-patterns:

- one giant `companies` JSON blob
- overwriting prior statement rows on restatement
- deriving core metrics only in Flutter
- storing only final ratios without formula lineage
- binding ETL directly to frontend-triggered refresh calls
- using `symbols` as the permanent company model

## Migration Strategy

Order matters.

### Phase 1

- add new v2 tables without breaking current app
- leave current serving tables in place

### Phase 2

- backfill normalized master data
- map `symbols` to `securities`
- map issuer identity to `companies`

### Phase 3

- begin raw ingestion pipeline
- ingest filings and macro data into immutable layers

### Phase 4

- normalize statements
- compute derived metrics
- expose new read models

### Phase 5

- move Flutter research surfaces onto new serving views
- demote old terminal-only tables to secondary support role

## Decisions Locked By This Document

1. The product is company-first, not ticker-first.
2. Raw data must be immutable.
3. Restatements must be versioned.
4. Metric outputs must be reproducible.
5. Screeners should read from serving snapshots, not compute everything in-request.
6. Supabase remains storage/query/auth infrastructure, not the main ETL compute engine.

## Open Questions

These should be resolved before SQL implementation:

1. Should `raw_records` remain generic, or be split earlier into source-specific raw tables?
2. Which canonical identifier should anchor `companies` across US and Indonesia first: CIK, internal UUID, or hybrid mapping?
3. How much document binary storage should remain in Supabase Storage versus external object storage later?
4. Which screener metrics are mandatory for MVP:
   - PE
   - PB
   - PS
   - EV/EBIT
   - EV/EBITDA
   - ROE
   - ROIC
   - Debt/Equity
   - FCF margin
5. How much ownership data is realistic for MVP in Indonesia versus US?

## Next Correct Document

After this schema document, the next planning artifact should be:

- ingestion topology and worker architecture

That should define:

- worker runtime
- scheduling
- raw storage conventions
- parser versioning conventions
- validation checkpoints
- retry and backfill strategy
