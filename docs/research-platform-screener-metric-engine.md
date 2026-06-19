# Taug Research Platform Screener and Metric Engine Design

Last updated: 2026-06-19

## Purpose

This document defines how Taug should calculate, store, explain, and serve financial metrics for screening and research workflows.

It is not enough for a screener to be fast.

It must also be:

- reproducible
- point-in-time aware
- source-traceable
- explicit about stale or missing inputs

If those qualities are missing, the screener will look useful while being structurally untrustworthy.

## Product Role

The screener is a core product feature.

It is not a side page.

It is one of the main reasons the platform needs:

- normalized statements
- price snapshots
- metric lineage
- quality and freshness scoring

The screener should help users answer:

- which companies are cheap relative to fundamentals
- which businesses meet quality thresholds
- which securities fit an investment style
- which names deserve deeper research next

## Design Rules

1. No metric exists without a definition.
2. No formula change is silent.
3. No screener result should depend on undocumented client-side calculations.
4. Metrics must be point-in-time queryable.
5. Missing and stale inputs must be visible, not hidden.
6. A fast serving snapshot is required, but it must trace back to reproducible inputs.
7. Do not materialize every possible ratio just because it can be computed.

## Metric Engine Scope

The metric engine should support four categories:

1. Reported facts
2. Normalized aggregates
3. Derived financial metrics
4. Price-dependent valuation metrics

### Reported facts

Examples:

- revenue
- gross profit
- operating income
- net income
- operating cash flow
- capex
- total assets
- total debt
- cash and equivalents
- shares outstanding

These should come from `financial_statement_items`.

### Normalized aggregates

Examples:

- TTM revenue
- TTM EBITDA
- TTM EPS
- average invested capital
- net debt

These are derived from reported facts but still close to statement logic.

### Derived financial metrics

Examples:

- gross margin
- operating margin
- net margin
- ROE
- ROA
- ROIC
- debt/equity
- current ratio
- FCF margin

### Price-dependent valuation metrics

Examples:

- PE
- PB
- PS
- EV/EBIT
- EV/EBITDA
- dividend yield
- market cap
- enterprise value

These combine statement data and price data.

## What The Screener Must Not Do

Do not:

- calculate canonical metrics only in Flutter
- use ad-hoc SQL expressions copied into many queries
- silently substitute latest price into historical financial periods without labeling the `as_of_date`
- treat missing input as zero unless the metric definition explicitly says so
- mix restated and superseded statement rows without point-in-time rules

## Core Entities

This document depends on schema v2 concepts:

- `metric_definitions`
- `metric_inputs`
- `metric_calculation_runs`
- `security_metric_snapshots`
- `security_price_snapshots`
- `screening_universe_memberships`
- `financial_statement_items`
- `financial_statements`
- `reporting_periods`

## Metric Definition Model

Every metric must have a first-class definition.

Required attributes:

- `code`
- `name`
- `category`
- `description`
- `formula_expression`
- `formula_version`
- `unit_type`
- `display_precision`
- `aggregation_mode`
- `point_in_time_policy`
- `staleness_policy`
- `is_active`

### `aggregation_mode`

Examples:

- `reported_period`
- `ttm`
- `latest_balance_sheet`
- `average_two_period`
- `price_as_of_date`

### `point_in_time_policy`

Examples:

- `filing_date_only`
- `period_end_plus_filing_availability`
- `latest_available`
- `price_date_matched`

Why:

- this makes temporal semantics explicit

### `staleness_policy`

Examples:

- `strict_fail`
- `allow_with_warning`
- `allow_with_max_age`

Why:

- some metrics should disappear if inputs are too stale
- others can still be shown with warning

## Formula Lineage

Formula lineage is mandatory.

### Minimum lineage requirements

For every metric snapshot, the platform should be able to answer:

- which formula definition produced it
- which formula version produced it
- which reporting period it used
- which price date it used, if any
- which statement version or filing version provided its inputs
- when it was calculated

### Recommended implementation

Store on `security_metric_snapshots`:

- `metric_definition_id`
- `formula_version`
- `reporting_period_id`
- `as_of_date`
- `calculation_run_id`
- `input_fingerprint`

Optional later enhancement:

- a normalized metric-input lineage table if explainability requirements become deeper

## Point-in-Time Rules

This is the most important correctness rule in the screener.

The system must distinguish:

- reporting period end
- filing availability date
- price date
- calculation date

### Example

If Q1 2026 ends on March 31, 2026 but the filing was available on May 10, 2026:

- a backtest or historical screener on April 15, 2026 must not use that Q1 filing yet
- a screener on May 20, 2026 may use it

This means metrics are not just period-based.

They are also availability-aware.

### Required policy

For MVP:

- use filing availability as the earliest usable timestamp for statement-derived metrics
- use explicit `as_of_date` for any price-dependent metric
- do not claim historical point-in-time accuracy unless both statement availability and price date are respected

## Stale and Missing Input Handling

Stale data is not the same as missing data.

The model must distinguish:

- input missing
- input stale
- input failed validation
- input available but estimated

### Recommended result flags

Each metric snapshot should carry or be joinable to:

- `computation_status`
- `stale_input_flag`
- `missing_input_flag`
- `validation_warning_flag`

Possible statuses:

- `ok`
- `missing_input`
- `stale_input`
- `validation_failed`
- `not_applicable`

Rule:

- a screener should be able to exclude bad rows, not just show nulls

## MVP Metric Catalog

The MVP should be intentionally narrow.

Do not try to ship 80 ratios first.

### Category A: valuation

- `pe`
- `pb`
- `ps`
- `ev_ebit`
- `ev_ebitda`

### Category B: profitability and quality

- `gross_margin`
- `operating_margin`
- `net_margin`
- `roe`
- `roa`
- `roic`

### Category C: leverage and liquidity

- `debt_equity`
- `net_debt_ebitda`
- `current_ratio`

### Category D: cash flow

- `fcf`
- `fcf_margin`
- `ocf_to_net_income`

### Category E: scale and market

- `market_cap`
- `enterprise_value`

### Category F: reference growth

- `revenue_yoy`
- `eps_yoy`

Why this set:

- enough for value and quality screening
- enough for research workflow
- still feasible without turning the first implementation into chaos

## Deferred Metrics

Defer these until the foundation is stable:

- complex factor composites
- quality rank percentiles across all markets
- Piotroski F-score
- Altman Z-score
- earnings surprise analytics
- custom user formula engine
- technical indicators as screener-first feature

Reason:

- they increase complexity faster than they increase trust

## Canonical Formula Notes

The exact formulas should be stored in `metric_definitions`, but the following conventions should be locked early.

### `pe`

- numerator: market price per share or market cap
- denominator: TTM diluted EPS or net income attributable to common, depending on implementation path

Rule:

- lock one consistent denominator convention for MVP
- do not mix basic and diluted EPS silently

### `pb`

- numerator: market cap
- denominator: common equity or book value attributable to common

### `ps`

- numerator: market cap
- denominator: TTM revenue

### `ev_ebit`

- numerator: enterprise value
- denominator: TTM EBIT

### `ev_ebitda`

- numerator: enterprise value
- denominator: TTM EBITDA

### `roic`

Recommended MVP convention:

- numerator: NOPAT
- denominator: average invested capital

Rule:

- if invested capital convention changes later, bump formula version

### `fcf`

Recommended MVP convention:

- operating cash flow minus capex

Rule:

- if capex sign conventions vary by source, normalize before metric stage

## Data Dependencies By Metric Type

### Statement-only metrics

Examples:

- gross margin
- net margin
- ROA
- current ratio

Dependencies:

- statement facts
- reporting periods
- filing availability

### Price-only metrics

Examples:

- market cap

Dependencies:

- price snapshot
- shares outstanding source

### Mixed metrics

Examples:

- PE
- PB
- PS
- EV/EBITDA

Dependencies:

- statement facts
- price snapshot
- share count
- debt and cash facts where applicable

## Recalculation Triggers

Metric recalculation should not be random or fully brute-force forever.

Primary triggers:

- new filing version ingested
- restatement detected
- metric formula version updated
- relevant price snapshot updated
- taxonomy mapping corrected

### Scope rules

- filing changes should recalculate only affected company or security scope when possible
- price updates may refresh price-dependent metrics without recomputing all statement-only metrics

## Serving Model

The screener must read from a serving layer, not compute everything live.

### Primary serving table

- `security_metric_snapshots`

This should be optimized for:

- security
- metric
- period
- as-of date
- universe filtering

### Supporting serving table

- `security_price_snapshots`

### Recommended read behavior

For a current screener:

- use the latest valid metric snapshot per security under the selected freshness rules

For historical or backtest-like analysis later:

- query by explicit `as_of_date`

## Screener Query Model

The filter model should be normalized, not prose-based.

Each filter should minimally express:

- `metric_code`
- `operator`
- `value`
- `value_type`
- `lookback_mode`
- `null_policy`

Examples:

- `pe < 10`
- `roic > 0.15`
- `debt_equity < 0.5`
- `fcf > 0`

### `null_policy`

Examples:

- `exclude`
- `include`
- `warn`

### `lookback_mode`

Examples:

- `latest`
- `latest_ttm`
- `latest_annual`
- `as_of_date`

## Saved Screener Model

Saved screeners should store:

- name
- description
- universe code
- filter definition
- sort definition
- selected columns

Do not store only a rendered SQL string.

Reason:

- it becomes hard to audit, migrate, or explain later

## Universe Model

Every screener starts with a universe.

MVP universes should be explicit:

- `us_common_stocks`
- `idx_equities`
- `nyse_nasdaq_equities`
- `active_primary_listings`

This should use `screening_universe_memberships`.

Why:

- filters become faster
- results become easier to explain
- user defaults become compatible with home-market preferences

## Freshness Rules For Screener Results

The screener should be able to apply freshness thresholds.

Minimum freshness dimensions:

- statement freshness
- price freshness
- ownership freshness later

MVP behavior:

- allow results with freshness warnings
- support optional strict exclusion for stale rows later

Do not pretend stale data is current.

## Explainability Requirements

For any row clicked from the screener later, the platform should be able to show:

- metric value
- formula name and version
- statement period used
- filing date or availability date used
- price date used
- freshness warning if applicable

This is a moat feature.

Do not treat it as optional fluff.

## Performance Rules

The screener should be fast because of serving snapshots and indexing, not because correctness is skipped.

Recommended indexing direction:

- by `metric_definition_id`
- by `security_id`
- by `reporting_period_id`
- by `as_of_date`

Later optimization options:

- materialized views by active universe
- precomputed latest-per-security views
- partitioning if metric volume becomes large

Do not start with partitions unless data scale proves it necessary.

## Anti-Patterns To Avoid

Avoid:

- recomputing all ratios on every screener request
- storing only final ranked outputs with no metric lineage
- letting Flutter combine raw statement rows into canonical ratios
- mixing different formula conventions under one metric code
- using latest available statement regardless of availability date in historical views
- treating negative denominators as normal output without policy

## Negative and Edge Cases

Some metrics should not always yield a numeric value.

Examples:

- PE with negative earnings
- EV/EBITDA with negative EBITDA
- debt/equity when equity is zero or negative

MVP rule:

- preserve numeric result only when definition says it remains meaningful
- otherwise return non-computable status, not fake precision

This policy must be explicit per metric.

## Recommendation For First SQL/Worker Implementation

Implement in this order:

1. `metric_definitions`
2. `metric_inputs`
3. `metric_calculation_runs`
4. `security_price_snapshots`
5. `security_metric_snapshots`
6. one worker job that computes a narrow MVP metric set

Suggested first computed set:

- market_cap
- enterprise_value
- pe
- pb
- ps
- gross_margin
- operating_margin
- roe
- debt_equity
- fcf

This is enough to prove the engine without overcommitting.

## Exit Criteria

This design is only successful when the platform can do all of the following:

1. Define a metric with explicit formula version.
2. Recompute a company metric set after a filing change.
3. Serve screener queries from snapshot tables.
4. Explain where a metric came from.
5. Distinguish missing, stale, and invalid inputs.
6. Avoid silent metric drift after formula updates.

## Next Correct Artifact

After this document, the best next planning artifact is:

- source strategy and ingestion priority plan

That should convert the architecture into concrete source-by-source execution order.
