# Taug Research Platform Source Strategy and Ingestion Priority Plan

Last updated: 2026-06-19

## Purpose

This document defines which sources Taug should use, in what order, and for what purpose.

It is not enough to list many sources.

The platform needs a source strategy that is:

- legal
- sustainable
- maintainable
- source-traceable
- aligned with the research workflow

The goal is not maximum source count.

The goal is dependable data foundations.

## Core Source Selection Rules

1. Prefer official primary sources.
2. Prefer sources with stable access patterns over convenient unofficial ones.
3. Use secondary sources only when their role is explicit.
4. Do not make the product dependent on undocumented scraping.
5. Every source must have a clear product purpose.
6. If a source is hard to maintain and not moat-critical, it should be deprioritized.

## Source Roles

Each source should be assigned one of four roles:

### Foundation

Used for core correctness.

Examples:

- filings
- financial statements
- macro time series
- issuer identity

### Supporting

Useful for enrichment or wider coverage, but not the primary system of record.

### Context

Useful for news, policy awareness, and workflow context, but not core to valuation correctness.

### Avoid As Core Dependency

May still be useful experimentally, but must not become a structural dependency for the platform.

## Source Priority Summary

### Phase 1 foundation

- SEC EDGAR
- FRED
- Bank Indonesia
- BPS

### Phase 2 foundation/supporting

- IDX
- company annual reports
- company quarterly reports

### Context layer

- official policy feeds
- selected news RSS feeds

### Defer or avoid as core

- Yahoo Finance
- Stooq as primary backbone
- undocumented or brittle scraping
- expensive exchange datasets before product-market proof

## Global Sources

## SEC EDGAR

Role:

- foundation

Use for:

- filing discovery
- filing documents
- filing versions
- company facts / XBRL facts
- issuer identifiers

Strengths:

- official source
- high legal sustainability
- high research relevance
- supports raw document and raw fact architecture directly

Weaknesses:

- US-centric
- requires parser discipline
- XBRL normalization is non-trivial

Why it is first:

- it defines the correct architecture for filings
- it provides enough depth to validate lineage, restatements, and screener foundations

MVP usage:

- ingest submissions and filing metadata
- store raw filing documents
- parse a narrow statement subset
- backfill a small US universe first

Do not skip this source if the product wants to be trusted for US equities.

## FRED

Role:

- foundation

Use for:

- macro time series
- interest rates
- inflation context
- benchmark economic indicators

Strengths:

- official
- stable
- easy to automate relative to filings
- strong fit for home-market-aware macro surfaces

Weaknesses:

- not a company fundamentals source
- can create false sense of completeness if used as general data backbone

MVP usage:

- ingest a curated set of macro series only
- support dashboard, macro panels, and research context

Recommended initial scope:

- Fed funds
- CPI
- unemployment
- GDP
- 10Y Treasury

## Nasdaq or Licensed Exchange Data

Role:

- defer

Use for:

- better reference data
- more complete exchange-grade coverage
- potential quality upgrade later

Strengths:

- high quality
- potentially lower ambiguity than free public composites

Weaknesses:

- licensing burden
- cost
- integration complexity

Recommendation:

- not needed for MVP foundation
- reassess after core research workflow proves itself

## Stooq

Role:

- supporting at most

Use for:

- experimental reference pricing
- prototype comparison feed

Weaknesses:

- not a reliable fundamentals foundation
- not strategically important enough to anchor architecture

Recommendation:

- do not center the platform around it

## Yahoo Finance

Role:

- avoid as core dependency

Why avoid:

- legal and access sustainability risk
- brittle integration assumptions
- too tempting as shortcut around proper architecture

Recommendation:

- do not use for foundational data correctness
- do not let it become the hidden dependency behind key metrics

## Investor Relations Websites

Role:

- supporting fallback

Use for:

- raw documents when official consolidated sources are incomplete
- company-published annual and quarterly reports

Strengths:

- primary-source documents
- useful in Indonesia and other markets with uneven structured APIs

Weaknesses:

- higher maintenance burden
- document layouts vary
- discovery is less standardized

Recommendation:

- use as document source, not as the main structured-data source

## Indonesia Sources

## IDX

Role:

- phase 2 foundation/supporting

Use for:

- issuer reference data
- listing metadata
- company disclosures where permitted
- exchange-specific market identity

Strengths:

- critical for Indonesia equity support
- likely necessary for proper local market identity

Weaknesses:

- access and licensing must be reviewed carefully
- may require more source-specific handling than US flows

MVP recommendation:

- start with reference and issuer master review first
- do not promise broad IDX statement coverage until document and access flow is proven

## OJK

Role:

- supporting

Use for:

- regulatory context
- financial sector oversight context
- potentially regulatory disclosures

Strengths:

- official
- trust-enhancing context layer

Weaknesses:

- not likely to be the main statements backbone

Recommendation:

- good supporting regulatory source
- not first screener foundation priority

## Bank Indonesia

Role:

- foundation

Use for:

- rates
- FX context
- macro indicators relevant to Indonesia home-market users

Strengths:

- official
- strong macro fit
- sustainable

Weaknesses:

- not issuer fundamentals source

MVP recommendation:

- pair with FRED as the first dual-home-market macro foundation

## BPS

Role:

- foundation

Use for:

- Indonesia macro and statistical series

Strengths:

- official
- useful for local macro context
- sustainable enough for research platform needs

Weaknesses:

- series selection discipline is required
- metadata harmonization may take work

MVP recommendation:

- start with a curated subset relevant to macro dashboard and research notes

## KSEI

Role:

- defer pending access review

Use for:

- ownership and shareholder-related enrichment

Strengths:

- potentially valuable for local ownership workflows

Weaknesses:

- access and licensing certainty not yet established
- not required for MVP screener foundation

Recommendation:

- do not block the core roadmap on it

## Company Annual and Quarterly Reports

Role:

- phase 2 foundation/supporting

Use for:

- raw document ingestion
- filing fallback
- statement extraction in markets where structured public pipelines are weaker

Strengths:

- primary-source documents
- critical for auditability

Weaknesses:

- parser effort
- layout variability
- document discovery complexity

Recommendation:

- mandatory as a document strategy
- especially important for Indonesia pathway

## News and Policy Sources

These are useful, but they are not the moat.

## Official Policy Feeds

Role:

- context

Use for:

- policy monitor
- macro event interpretation context

Recommendation:

- keep, but do not let policy feeds dominate architecture priority

## News RSS Feeds

Role:

- context

Use for:

- awareness
- workflow context
- research queue generation

Recommendation:

- keep as context layer only
- do not treat them as data-correctness foundation

## Source Decision Matrix

### Tier A: build now

- SEC EDGAR
- FRED
- Bank Indonesia
- BPS

Reason:

- official
- sustainable
- directly aligned with core architecture

### Tier B: build after foundation is stable

- IDX
- annual reports
- quarterly reports
- OJK

Reason:

- strategically important
- somewhat more source-specific and operationally heavier

### Tier C: keep as context

- policy feeds
- news RSS

Reason:

- useful product layer
- not worth architecture-first priority

### Tier D: avoid as core dependency

- Yahoo Finance
- undocumented scraping

Reason:

- sustainability and legal risk

## Recommended Source-by-Source Delivery Order

## Wave 1

- SEC EDGAR filing discovery
- SEC raw document storage
- SEC filing version model

Why:

- unlocks lineage and statement architecture

## Wave 2

- SEC statement extraction for a narrow US universe
- FRED curated macro series

Why:

- unlocks company research plus macro context

## Wave 3

- Bank Indonesia curated macro series
- BPS curated macro series

Why:

- establishes Indonesia home-market support without overreaching into full local equity parsing too early

## Wave 4

- IDX issuer/reference data
- annual report ingestion
- quarterly report ingestion

Why:

- this is the correct point to expand Indonesia issuer depth

## Wave 5

- OJK regulatory context
- KSEI if access path is validated

Why:

- enrichment after core issuer and screener foundations exist

## Maintenance Burden Expectations

### Low to medium burden

- FRED
- Bank Indonesia
- BPS

### Medium burden

- SEC metadata and filing discovery
- policy feeds

### Medium to high burden

- SEC XBRL normalization
- IDX reference and disclosure workflows
- annual report parsing
- quarterly report parsing

### High uncertainty burden

- KSEI
- unofficial or brittle public web flows

## Legal and Sustainability Position

The platform should be able to defend every core source choice.

That means:

- official where possible
- documented access patterns where possible
- no hidden dependency on terms-fragile shortcuts

The product is trying to build trust.

It should not hide a shaky data backbone under a polished UI.

## Source-Specific MVP Boundaries

### SEC

MVP promise:

- filing metadata
- raw documents
- narrow statement extraction

Do not promise:

- perfect full-market XBRL normalization on day one

### FRED / BI / BPS

MVP promise:

- curated macro series with freshness tracking

Do not promise:

- every possible series immediately

### IDX / annual reports / quarterly reports

MVP promise later:

- issuer identity and selected report coverage

Do not promise early:

- full Indonesia statement normalization until document flow is proven

## What This Strategy Implies For Engineering

1. Worker modules should be source-specific at the fetch layer.
2. Normalization should converge into common canonical entities.
3. Raw source metadata must track licensing notes and official status.
4. Source onboarding should be incremental, not all-at-once.
5. Each new source should justify its maintenance burden.

## Exit Criteria

This strategy is only useful if it constrains execution.

The source strategy is successful when:

1. The first worker implementation starts with SEC, FRED, BI, and BPS.
2. The team does not build core product assumptions on Yahoo Finance or undocumented scraping.
3. Indonesia support expands in the right order: macro first, issuer depth second.
4. Context feeds remain context feeds, not architecture drivers.

## Next Correct Artifact

After this document, the next best artifact is:

- a concrete phase-3 implementation checklist for SEC filings foundation

That should convert the current planning work into:

- first migrations
- first worker job list
- first raw storage conventions to implement
