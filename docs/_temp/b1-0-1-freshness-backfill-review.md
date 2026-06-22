# B1.0.1 — Freshness Backfill Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Backfilled `last_fetched_at` for all 646 historical metric snapshots using `created_at` as the source timestamp. Metric freshness now returns meaningful values instead of `unknown`. No regressions. 74 tests pass.

---

## Snapshot Audit

| Metric | Count |
|---|---|
| Total snapshots | 646 |
| With last_fetched_at (before) | 0 |
| Without last_fetched_at (before) | 646 |
| Status ok | 429 |
| Status missing_input | 217 |
| created_at available | 646 |

---

## Backfill Strategy

**Chosen approach:** `last_fetched_at = created_at`

**Rationale:** `created_at` is the most accurate available timestamp. It represents when the snapshot was actually computed by the worker. This is semantically equivalent to `last_fetched_at` — the metric was "fetched" (computed) at that time.

**Alternatives considered:**
- `updated_at` — not always different from `created_at`
- Current timestamp — would fabricate freshness
- NULL — would leave metrics as `unknown`

**Risk:** Minimal. `created_at` is a reliable existing timestamp. No data invented.

---

## Changes Made

**File:** `workers/taug_worker/supabase_rest.py` (from B1 — already committed)

Added `last_fetched_at` to both insert and update paths in `upsert_security_metric_snapshot()`.

**Backfill:** Direct PATCH on `security_metric_snapshots` table. Updated 646 rows.

---

## Validation Results

### Before

```
All companies: metric_freshness = unknown
```

### After

| Company | Metric Freshness | last_fetched_at |
|---|---|---|
| Accenture | fresh | 2026-06-20 |
| Adobe | fresh | 2026-06-20 |
| Alphabet | fresh | 2026-06-19 |
| Amazon | fresh | 2026-06-19 |
| American Tower | fresh | 2026-06-20 |
| Apple | fresh | 2026-06-19 |
| Broadcom | fresh | 2026-06-20 |
| Caterpillar | fresh | 2026-06-20 |
| Chevron | fresh | 2026-06-20 |
| Cisco | fresh | 2026-06-20 |
| Coca-Cola | fresh | 2026-06-20 |
| Costco | fresh | 2026-06-20 |
| Exxon | fresh | 2026-06-20 |
| Honeywell | fresh | 2026-06-20 |
| Intel | fresh | 2026-06-20 |

All 32 companies now show `fresh` for metric freshness.

---

## Regression Checks

| Check | Status |
|---|---|
| Screener works | ✅ |
| Metric views work | ✅ |
| Rankings work | ✅ |
| Existing metric values unchanged | ✅ |
| 74 tests pass | ✅ |

---

## Risks

| Risk | Status |
|---|---|
| Data corruption | None — only added timestamp to existing rows |
| Metric values changed | None — only metadata updated |
| Screener regressions | None |

---

## Recommendation

**Accept backfill.** All historical metrics now participate in the freshness framework. `company_freshness_v` returns meaningful values for all dimensions.
