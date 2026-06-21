# TAUG Risk Register

**Created:** 2026-06-21
**Purpose:** Track unresolved risks with probability, impact, and mitigation.

---

## Active Risks

### R1: Zero Test Coverage

**Probability:** High (100% — no tests exist)
**Impact:** High (no regression detection, no CI validation)
**Mitigation:** Establish test infrastructure, add unit tests for critical paths
**Owner:** QA Agent
**Status:** Open
**Phase Identified:** B1.1
**Notes:** All 27 features shipped without tests. Critical for production readiness.

---

### R2: --WASM Build Compatibility

**Probability:** Medium (some packages may not support WASM)
**Impact:** High (build failure blocks deployment)
**Mitigation:** Test --wasm build before deploying, identify incompatible packages
**Owner:** DevOps Agent
**Status:** Open
**Phase Identified:** B5
**Notes:** --wasm flag added to deploy workflow but not yet tested.

---

### R3: Settings Mutation Errors Invisible

**Probability:** High (settings page doesn't observe error.value)
**Impact:** Medium (user changes timezone/density, failure is silent)
**Mitigation:** Add UI surface for settings mutation errors (snackbar or inline)
**Owner:** Frontend Agent
**Status:** Open
**Phase Identified:** B1.1
**Notes:** updateTimezone and updateDensityMode set error.value but settings page doesn't read it.

---

### R4: Inline Supabase Queries in Presentation Layer

**Probability:** High (Add Position dialog queries Supabase directly)
**Impact:** Medium (bypasses repository pattern, harder to test/maintain)
**Mitigation:** Refactor to use repository pattern
**Owner:** Backend Agent
**Status:** Open
**Phase Identified:** B2
**Notes:** portfolio_workspace_page.dart line 254-262 queries companies table directly.

---

### R5: Legacy Holdings System Orphaned

**Probability:** Medium (two separate portfolio systems exist)
**Impact:** Medium (user confusion, duplicate class names)
**Mitigation:** Deprecate legacy holdings or clearly separate with renamed classes
**Owner:** Architecture Agent
**Status:** Open
**Phase Identified:** B2
**Notes:** portfolio_holdings table + PortfolioProvider (legacy) vs portfolio_positions + PortfolioWorkspaceProvider (new).

---

### R6: No Keyboard Shortcuts

**Probability:** High (not implemented)
**Impact:** Medium (desktop UX degraded for power users)
**Mitigation:** Add keyboard shortcuts for tab switching, navigation, dialog dismiss
**Owner:** Frontend Agent
**Status:** Open
**Phase Identified:** B2
**Notes:** Financial terminal users expect keyboard navigation.

---

### R7: Data Freshness Thresholds May Not Match User Expectations

**Probability:** Low (thresholds are reasonable)
**Impact:** Low (users may expect different freshness levels)
**Mitigation:** Make thresholds configurable in future
**Owner:** Data Agent
**Status:** Open
**Phase Identified:** B3
**Notes:** Current thresholds: filings 30/90/365d, metrics 30/90/365d, prices 1/7/30d.

---

### R8: Quality Breakdown Popover Overflow on Small Screens

**Probability:** Low (fixed width 320px)
**Impact:** Low (content may be clipped)
**Mitigation:** Use Overlay instead of showMenu for better positioning
**Owner:** Frontend Agent
**Status:** Open
**Phase Identified:** B3
**Notes:** Works on desktop but may have issues on smaller viewports.

---

### R9: compute() Isolate Overhead for Small Payloads

**Probability:** Low (200 rows is worth the overhead)
**Impact:** Low (slight latency increase for small datasets)
**Mitigation:** Only use compute() for large datasets (>50 items)
**Owner:** Backend Agent
**Status:** Open
**Phase Identified:** B5
**Notes:** getTopMovers typically has 50-200 items.

---

### R10: No Automated Stale Thesis Detection

**Probability:** High (not implemented)
**Impact:** Medium (theses may become stale without user awareness)
**Mitigation:** Add time-based or event-based triggers to mark theses as needing review
**Owner:** Backend Agent
**Status:** Open
**Phase Identified:** B2
**Notes:** reviewNeeded status exists but nothing triggers it automatically.

---

## Closed Risks

### R11: Silent Mutation Failures (CLOSED)

**Probability:** High (100% — all mutations were silent)
**Impact:** High (data loss, user confusion)
**Mitigation:** Fixed with error propagation + _isMutating guards
**Owner:** Backend Agent
**Status:** Closed
**Phase Identified:** B1.1
**Resolution:** 17 mutations now propagate errors with debugPrint

---

### R12: PortfolioProvider Naming Collision (CLOSED)

**Probability:** High (two classes with same name)
**Impact:** High (compile error if both imported)
**Mitigation:** Renamed workspace variant to PortfolioWorkspaceProvider
**Owner:** Frontend Agent
**Status:** Closed
**Phase Identified:** B2
**Resolution:** Clear naming prevents confusion and compile errors

---

### R13: Thesis Dialog Incomplete (CLOSED)

**Probability:** High (4 fields missing)
**Impact:** High (thesis lacks structured thinking fields)
**Mitigation:** Added assumptions, catalysts, risks, exitConditions to dialog
**Owner:** Frontend Agent
**Status:** Closed
**Phase Identified:** B2
**Resolution:** All 10 fields from CompanyThesis model now capturable

---

### R14: No Thesis → Position Connection (CLOSED)

**Probability:** High (no UI linkage)
**Impact:** Critical (Research → Decision → Portfolio loop broken)
**Mitigation:** Added thesis selector + "Create Position" button
**Owner:** Frontend Agent
**Status:** Closed
**Phase Identified:** B2
**Resolution:** Full bridge implemented with two entry points

---

### R15: Quality Score Meaningless Without Context (CLOSED)

**Probability:** High (only overall_score fetched)
**Impact:** Medium (users can't understand WHY quality is low)
**Mitigation:** Fetch all 7 component scores + breakdown popover
**Owner:** Backend Agent
**Status:** Closed
**Phase Identified:** B3
**Resolution:** QualityScoreDetail model with full breakdown

---

## Risk Summary

| Status | Count |
|---|---|
| Open | 10 |
| Closed | 5 |
| **Total** | **15** |

### Top Risks by Impact

1. **R1: Zero Test Coverage** — High impact, 100% probability
2. **R2: --WASM Build Compatibility** — High impact, medium probability
3. **R5: Legacy Holdings System** — Medium impact, medium probability
4. **R4: Inline Supabase Queries** — Medium impact, high probability

### Recommended Mitigations

1. Establish test infrastructure (highest priority)
2. Test --wasm build before deploying
3. Refactor inline queries to repository pattern
4. Deprecate or clearly separate legacy holdings

---

*This register is continuously updated. Open risks require mitigation plans.*
