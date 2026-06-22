# B1 — Freshness Framework Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Implemented the first version of the TAUG Freshness Framework. Fixed metric snapshot freshness tracking (was NULL), created `company_freshness_v` serving view with 4-dimension freshness scoring, and designed a simple Fresh/Aging/Stale/Expired classification system.

**Changes:** 2 files modified, 1 migration created, 74 tests pass.

---

## Current State Audit

### Existing Timestamps (Before)

| Table | last_reported_at | last_fetched_at | last_verified_at |
|---|---|---|---|
| reporting_periods | ✅ populated | ✅ populated | ✅ populated |
| financial_statements | ✅ populated | ✅ populated | ✅ populated |
| security_metric_snapshots | ❌ NULL | ❌ NULL | ❌ NULL |
| security_price_snapshots | — | ✅ populated | ❌ NULL |
| macro_series | — | ✅ populated | — |
| raw_documents | — | ✅ populated | ✅ populated |

### Key Gap

`security_metric_snapshots` had freshness columns but they were never populated by the worker. All 646 metric snapshots had `last_fetched_at = NULL`.

---

## Freshness Requirements

| Entity | reported_at | fetched_at | verified_at |
|---|---|---|---|
| Filings | filing_date | (filing_version.ingested_at) | — |
| Statements | published_at | last_fetched_at | last_verified_at |
| Metric Snapshots | as_of_date | last_fetched_at | — |
| Price Snapshots | price_date | last_fetched_at | — |
| Data Quality | score_date | created_at | — |

---

## Schema Changes

### Migration: `20260620001300_add_freshness_view.sql`

Created `company_freshness_v` — unified freshness dashboard per company.

**Columns:**
- `filing_freshness` — based on latest 10-K/10-Q filing_date
- `statement_freshness` — based on latest statement published_at
- `metric_freshness` — based on metric snapshot last_fetched_at
- `price_freshness` — based on price snapshot last_fetched_at
- `quality_score` — latest data quality score

### Worker Fix: `supabase_rest.py`

Added `last_fetched_at` to both insert and update paths in `upsert_security_metric_snapshot()`.

---

## Freshness Model

### Scoring System

| Score | Filing | Statement | Metric | Price |
|---|---|---|---|---|
| fresh | < 30 days | < 30 days | < 30 days | < 1 day |
| aging | 30-90 days | 30-90 days | 30-90 days | 1-7 days |
| stale | 90-365 days | 90-365 days | 90-365 days | 7-30 days |
| expired | > 365 days | > 365 days | > 365 days | > 30 days |
| unknown | no data | no data | no data | no data |

**Rationale:** Different thresholds for different data types. Price data changes daily (fresh < 1 day). Filing data changes quarterly (fresh < 30 days). This matches user expectations for each data type.

---

## Freshness Scoring

Simple classification, no complex algorithm:

```sql
CASE
  WHEN timestamp >= NOW() - INTERVAL '30 days' THEN 'fresh'
  WHEN timestamp >= NOW() - INTERVAL '90 days' THEN 'aging'
  WHEN timestamp >= NOW() - INTERVAL '365 days' THEN 'stale'
  ELSE 'expired'
END
```

Price uses tighter thresholds (1 day, 7 days, 30 days) because price data changes daily.

---

## Validation Results

### NVDA

| Dimension | Status | Value |
|---|---|---|
| Filing | aging | 2026-04-17 |
| Statement | aging | 2026-05-20 |
| Metric | unknown | NULL (not yet recomputed) |
| Price | fresh | 2026-06-20 |
| Quality | 83% | — |

### JPM

| Dimension | Status | Value |
|---|---|---|
| Filing | unknown | no 10-K/10-Q |
| Statement | unknown | no statements |
| Metric | unknown | no metrics |
| Price | fresh | 2026-06-20 |
| Quality | 25% | — |

### KO

| Dimension | Status | Value |
|---|---|---|
| Filing | aging | 2026-04-28 |
| Statement | aging | 2026-04-30 |
| Metric | unknown | NULL (not yet recomputed) |
| Price | fresh | 2026-06-20 |
| Quality | 79% | — |

### PLD

| Dimension | Status | Value |
|---|---|---|
| Filing | aging | 2026-04-28 |
| Statement | aging | 2026-04-30 |
| Metric | unknown | NULL (not yet recomputed) |
| Price | fresh | 2026-06-20 |
| Quality | 83% | — |

### Summary

- **Price freshness:** All companies `fresh` (daily sync working)
- **Filing freshness:** Mostly `aging` (quarterly filings, expected)
- **Statement freshness:** Matches filing freshness
- **Metric freshness:** All `unknown` (existing snapshots have NULL last_fetched_at)
- **Quality scores:** 25%-83%

---

## Risks

| Risk | Status | Mitigation |
|---|---|---|
| Metric freshness unknown for existing data | Known | Will populate on next metric recompute |
| JPM has no filing/statement freshness | Known | No 10-K/10-Q data |
| Price freshness thresholds may be too tight | Acceptable | Can adjust later |

---

## Future UI Usage

### Company Page
```
Last Filing: 10-Q (2026-04-17) — aging
Last Statement: 2026-05-20 — aging
Last Metric: unknown
Last Price: 2026-06-20 — fresh
Data Quality: 83%
```

### Screener Badge
```
NVDA — Fresh ⬤
JPM — Unknown ⚪
```

### Research Workspace
```
Data Freshness: 7/32 companies have fresh metrics
```

---

## Recommendation

1. **Accept framework.** The freshness view is functional and provides the foundation for UI display.

2. **Recompute metrics** to populate `last_fetched_at` on existing snapshots. This will make metric freshness visible.

3. **Consider tighter thresholds** for specific use cases (e.g., screener freshness filter).
