# A2.2.2 — Metric Visibility Fix Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Fixed metric visibility issue in `company_metric_snapshot_v` by adding a CASE expression to the ORDER BY clause that prefers `ok` snapshots over `missing_input`. JNJ improved from 5→13 ok metrics, UNH from 3→15, VISA from 5→6. No regressions on unaffected companies. 74 tests pass.

---

## Changes Made

**File:** `supabase/migrations/20260620001200_fix_metric_snapshot_view_ordering.sql`

**Change:** Modified `company_metric_snapshot_v` ORDER BY from:

```sql
ORDER BY sms.security_id, sms.metric_definition_id, sms.as_of_date DESC
```

to:

```sql
ORDER BY sms.security_id, sms.metric_definition_id,
         CASE WHEN sms.computation_status = 'ok' THEN 0 ELSE 1 END,
         sms.as_of_date DESC
```

**Effect:** `ok` snapshots are preferred over `missing_input`. Among snapshots with the same status, the most recent is selected.

---

## Validation Results

### Affected Companies (Before → After)

| Company | Before (ok) | After (ok) | Improvement |
|---|---|---|---|
| JNJ | 5 | 13 | +8 metrics |
| VISA | 5 | 6 | +1 metric |
| UNH | 3 | 15 | +12 metrics |

### JNJ — After Fix

| Metric | Value | Status |
|---|---|---|
| gross_margin | 67.88% | ✅ now visible |
| net_margin | 28.46% | ✅ now visible |
| roe | 33.02% | ✅ now visible |
| roa | 13.34% | ✅ now visible |
| pe | 20.51 | ✅ now visible |
| pb | 6.77 | ✅ now visible |
| debt_equity | 0.46 | ✅ |
| operating_margin | MISSING | ❌ (no ok snapshot) |
| ev_ebitda | MISSING | ❌ (no ok snapshot) |

### UNH — After Fix

| Metric | Value | Status |
|---|---|---|
| pe | 30.20 | ✅ now visible |
| ev_ebitda | 21.49 | ✅ now visible |
| operating_margin | 4.24% | ✅ now visible |
| net_margin | 2.69% | ✅ now visible |
| roa | 3.86% | ✅ now visible |
| roe | MISSING | ❌ (no ok snapshot) |
| pb | MISSING | ❌ (no ok snapshot) |

### VISA — After Fix

| Metric | Value | Status |
|---|---|---|
| operating_margin | 62.63% | ✅ |
| net_margin | 52.79% | ✅ |
| roa | 34.24% | ✅ |
| gross_margin | MISSING | ❌ (no ok snapshot) |
| roe | MISSING | ❌ (no ok snapshot) |

---

## Unaffected Companies (Regression Check)

| Company | Status | ok | missing |
|---|---|---|---|
| NVDA | ✅ CLEAN | 17 | 2 |
| ORCL | ✅ CLEAN | 14 | 5 |
| CSCO | ✅ CLEAN | 19 | 0 |
| ADBE | ✅ CLEAN | 19 | 0 |
| AVGO | ✅ CLEAN | 12 | 7 |
| CRM | ✅ CLEAN | 19 | 0 |
| INTC | ✅ CLEAN | 16 | 3 |
| ACN | ✅ CLEAN | 10 | 9 |

All unaffected companies maintain their previous metric counts. No regressions.

---

## Screener Validation

| Test | Result |
|---|---|
| ROE ranking | ✅ More companies now visible |
| PE ranking | ✅ JNJ (20.51) and UNH (30.20) now visible |
| D/E ranking | ✅ JNJ (0.46) now visible |
| GM > 50% | ✅ JNJ (67.88%) now included |

---

## Risks

| Risk | Status | Notes |
|---|---|---|
| Hidden ok snapshots now exposed | Expected | Some may have stale data |
| Historical snapshots preserved | ✅ | No data deleted |
| Unaffected companies unchanged | ✅ | No regressions |

---

## Recommendation

**Accept fix.** The view now correctly prefers valid data over missing data. All historical snapshots preserved. No regressions.
