# Taug Stocks-First Terminal Roadmap

## Objective

Build Taug into a credible open-source financial terminal focused on:

- Stocks workflows first
- News, politics, and government intelligence second
- Charts as a supporting tool, not the product center
- Legal and clearly attributed data sources only

This roadmap replaces the previous implicit bias toward chart-first and synthetic market panels.

## Product Positioning

Taug v1 is not a Bloomberg clone. It is an open terminal for:

- Market monitoring
- Equity watchlists
- Corporate and macro news tracking
- Government and policy intelligence
- Filings and economic releases
- Portfolio observation

The product must be explicit about data class:

- `REALTIME`
- `DELAYED`
- `EOD`
- `DERIVED`
- `OFFICIAL`
- `SYNDICATED`

Every market-facing panel must expose source and latency metadata.

## Core Principles

1. Never scrape or automate against a source that prohibits automated collection.
2. Never present synthetic or inferred market microstructure as real market data.
3. Always separate source ingestion, normalization, caching, and UI rendering.
4. Treat news, policy, regulation, and filings as first-class terminal data.
5. Optimize for Flutter Web WASM constraints from the start.

## Stocks-First Scope

### Included in v1

- Equity watchlists
- Equity quote snapshots
- Delayed or EOD charting
- News feed with source attribution
- Politics and government monitoring panels
- Economic calendar and release tracker
- SEC filings and company event tracking
- Portfolio monitoring

### Explicitly excluded from v1

- Real market depth for equities without licensed feed access
- Real time-and-sales for equities without licensed feed access
- Cross-market low-latency professional data claims
- Synthetic order book or fabricated trades in production

## Legal Data Strategy

### Tier A: Official public and regulator sources

Use these as the trust backbone of the terminal:

- SEC EDGAR API for filings, ticker metadata, and structured XBRL data
- FRED API for macro series and release-linked economic data
- BLS API for labor, inflation, and other published economic series
- ECB and other central-bank/public feeds where relevant
- Official government press releases and agency RSS feeds

Use cases:

- Politics and government page
- Economic releases page
- Company filings feed
- Macro dashboard

### Tier B: Licensed or permitted market APIs

Use these only within their allowed scope:

- Twelve Data for delayed, EOD, or permitted quote/chart access
- Vendor-specific APIs added later through BYO key or paid connector

Use cases:

- Watchlist quote snapshots
- Delayed chart data
- Movers and portfolio pricing

### Tier C: Syndicated feeds

Use only where redistribution/display is allowed:

- RSS feeds from publishers that permit feed display and linking
- Official newsroom RSS from regulators, ministries, and agencies

Use cases:

- News page
- Politics/government feed
- Policy alerts

### Tier D: Derived internal data

Built internally from legal upstream sources:

- Top movers
- Quote delta summaries
- Sector heatmaps
- Portfolio analytics
- News topic clustering

### Forbidden

- Yahoo Finance scraping or undocumented endpoint dependence
- HTML scraping of sources with available licensed or official APIs when terms are unclear or restrictive
- Fabricated trades, depth, or price history presented as live market data

## Terminal Data Domains

### 1. Market Quotes

Purpose:

- Power watchlist, portfolio valuation, movers, compact quote pages

Requirements:

- Canonical instrument table
- Vendor symbol mapping
- Batch quote ingestion
- Cache-first reads
- Source and timestamp labeling

### 2. News

Purpose:

- Surface market-moving headlines quickly

Requirements:

- Source attribution
- Deduplication by canonical URL and title hash
- Topic tagging
- Symbol association
- Importance and breaking heuristics

### 3. Politics and Government

Purpose:

- Track policy, elections, sanctions, ministries, regulators, central banks, and legislative events

Primary source classes:

- Government newsroom RSS
- Central bank announcements
- Regulator press releases
- Parliamentary/congressional calendars where available
- Sanctions and enforcement releases from official agencies

Requirements:

- Country tagging
- Agency tagging
- Policy category tagging
- Severity ranking
- Timeline view with source links

### 4. Economic Releases

Purpose:

- Track scheduled and released macro events with actual/forecast/previous

Requirements:

- Official/public API first
- Timezone-safe release modeling
- Event provenance
- Historical revision support where available

### 5. Filings and Corporate Disclosures

Purpose:

- Make filings a core terminal primitive, not an afterthought

Requirements:

- SEC submissions ingestion
- Filing type normalization
- Company-specific filings feed
- Material filing alerting

## Recommended Information Architecture

### Main tabs for v1

- `Brief`
- `Market`
- `Watchlists`
- `Chart`
- `News`
- `Policy`
- `Calendar`
- `Portfolio`
- `Settings`

### Brief tab layout

Desktop-first multi-panel shell:

- Left: ranked top-impact news and policy
- Right top: market movers
- Right bottom: macro calendar snapshot

Charts remain available, but are not the default landing surface.

## Current UI Baseline

- 12px minimum readable typography
- 2px-grid-derived spacing system
- Fixed-height rows and cards for terminal consistency
- Source and latency labels are passive status indicators, not interactive controls
- Default chart mode is `Line`

## Target Data Architecture

### Ingestion layer

Responsibilities:

- Pull vendor and official feeds
- Validate payloads
- Normalize into internal DTOs
- Attach provenance metadata
- Apply retry, timeout, and rate limiting

Location:

- `supabase/functions/`
- scheduled jobs or external worker later if needed

### Normalization layer

Responsibilities:

- Convert vendor payloads into canonical models
- Map vendor symbol formats into instrument master records
- Assign source metadata

Suggested location:

- `lib/core/data_sources/`
- `lib/core/normalization/`

### Cache layer

Responsibilities:

- Store latest quotes
- Store candle history
- Store news items
- Store policy/government items
- Store macro events
- Store filing events

Backed by:

- Supabase schema tables with strict provenance columns

### Presentation layer

Responsibilities:

- Read compact cached models
- Render source badges
- Avoid heavy client transforms
- Apply signal-level granularity

## Schema Additions

The current schema needs expansion.

### Required new tables

- `instrument_sources`
- `quote_snapshots`
- `news_sources`
- `policy_events`
- `filing_events`
- `macro_release_sources`

### Required provenance fields

For every cached market/news/event row:

- `source_vendor`
- `source_type`
- `source_url`
- `latency_class`
- `is_official`
- `is_synthetic`
- `fetched_at`
- `as_of`

## Execution Phases

## Phase 0: Trust Reset

Goal:

- Remove misleading data behavior and establish source truth

Tasks:

- Remove Yahoo fallback code paths
- Remove synthetic order book and synthetic trades from production
- Mark unsupported panels as unavailable until backed by legal sources
- Add source metadata model and UI badges
- Disable runtime font fetching for deterministic startup
- Update README and architecture docs to reflect real source strategy

Definition of done:

- No illegal/risky fallback source remains
- No synthetic market panel remains visible as real data
- Every data panel displays source and freshness

## Phase 1: Stocks Foundation

Goal:

- Make watchlists, quote snapshots, and portfolio reliable

Tasks:

- Add canonical instrument master and source mapping
- Add `quote_snapshots` cache table
- Replace per-symbol edge function fanout with batch ingestion and cache reads
- Refactor watchlist, market, and portfolio repositories to read cached snapshots
- Add request versioning and concurrent load guards

Definition of done:

- Watchlist loads from cache
- Portfolio pricing uses cached snapshots
- Market movers derive from snapshot universe, not hardcoded symbol list alone

## Phase 2: News Intelligence

Goal:

- Turn news into a terminal-grade information stream

Tasks:

- Normalize publisher feeds
- Add dedupe and canonical URL resolution
- Add topic, region, and symbol tagging
- Add importance scoring
- Add breaking label logic
- Add source filter and topic filter UI

Definition of done:

- News feed is attributed, deduped, filterable, and not just an RSS dump

## Phase 3: Politics and Government Feed

Goal:

- Add policy, regulator, and government intelligence as a first-class module

Tasks:

- Build ingestion for official agency and government feeds
- Define `policy_events` schema
- Tag by country, agency, policy area, and severity
- Build timeline UI and alert filters

Example source categories:

- Central bank statements
- Treasury/finance ministry releases
- White House and cabinet briefings
- SEC, DOJ, FTC, OFAC, BIS, Federal Reserve
- Parliament/congress announcements where feed access is official

Definition of done:

- Users can monitor policy and government actions alongside market instruments

## Phase 4: Economic Calendar and Releases

Goal:

- Replace brittle scraping with official or properly licensed macro event ingestion

Tasks:

- Replace HTML parsing path
- Use official/public APIs where possible
- Preserve actual, forecast, previous, release time, and revisions
- Add country and importance filters

Definition of done:

- No fake or hardcoded live economic events

## Phase 5: Filings Terminal

Goal:

- Make disclosures a major product differentiator

Tasks:

- Ingest SEC submissions
- Normalize filing types
- Associate filings with symbols
- Add watchlist-linked filing feed
- Add material filing alert classification

Definition of done:

- Selected symbols show latest filings and filing-type filters

## Phase 6: Charts and Realtime Upgrades

Goal:

- Keep charts, but demote them to a robust supporting component

Tasks:

- Refactor chart pipeline to cache-first
- Offload heavy parse/mapping with `compute()`
- Add background indicator computation
- Add realtime connectors only for markets with permitted feeds

Definition of done:

- Chart interactions do not dominate architecture or product identity

## Flutter/WASM Engineering Rules

For all phases:

- Offload JSON decoding and large list mapping with `compute()` once payloads exceed threshold
- Throttle stream-driven signal updates to at most every 100ms
- Use `RepaintBoundary` for every frequently updating quote cell
- Avoid runtime font fetching
- Use viewport-bound lists with explicit row heights
- Avoid replacing large signal collections when patch updates are enough

## Immediate Work Order

Start with this exact sequence:

1. Phase 0 trust reset
2. Phase 1 stocks foundation
3. Phase 2 news intelligence
4. Phase 3 politics and government feed
5. Phase 4 economic calendar cleanup
6. Phase 5 filings terminal
7. Phase 6 charts and realtime upgrades

## First Concrete Refactor Batch

The first coding batch should do only these items:

1. Remove Yahoo fallback and synthetic production panels
2. Add shared source metadata model
3. Add source/freshness badges to watchlist, market, chart, news, and calendar panels
4. Disable runtime font fetching
5. Replace chart page local state with a provider-driven state model and request guards
6. Prepare schema migration for quote snapshots and provenance fields

## Success Metric for v1

Taug v1 succeeds if a user can:

- track a stock watchlist,
- read credible linked news,
- monitor filings,
- follow government and policy developments,
- inspect macro releases,
- and understand exactly how fresh and official each data point is.

That is a strong terminal product even before true professional realtime equities arrive.
