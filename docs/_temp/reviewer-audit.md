# TAUG Reviewer Audit Log

**Created:** 2026-06-21
**Owner:** Reviewer Agent (independent)
**Purpose:** Independent review findings. Build may NOT write this file.

---

## B1.1 Critical Reliability Hotfix — Audit

### Accepted Work

| Item | Status | Notes |
|---|---|---|
| Error propagation on 17 mutations | ✅ Accepted | All mutations now set error.value with debugPrint |
| _isMutating race guards | ✅ Accepted | Prevents double-submit on all mutation methods |
| Stale error clearing | ✅ Accepted | error.value cleared before each mutation |
| mutationError signal separation | ✅ Accepted | WorkspaceProvider uses separate signal to avoid full-page error regression |
| dynamic → WatchlistItem fix | ✅ Accepted | watchlist_page.dart line 410 |

### Rejected Work

| Item | Reason |
|---|---|
| MutationState<T> sealed class | Over-engineered for hotfix scope. 28 per-mutation signals unnecessary when UI is modal. |
| Per-mutation signals (28 total) | Maintenance burden outweighs benefit. Can add later if concurrent mutations needed. |

### Concerns

| Concern | Severity | Status |
|---|---|---|
| Settings mutations have no UI surface for errors | Medium | Deferred — settings page doesn't read error.value |
| _isMutating blocks unrelated mutations silently | Medium | Accepted trade-off — UI is modal, only 1 mutation at a time |
| Zero test coverage for all modified providers | High | Deferred — no test infrastructure exists |

### Risk Areas

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Stale error from prior operation affects current operation | Low | Medium | error.value cleared at mutation entry |
| mutationError never cleared after consumption | Low | Low | Auto-reset not implemented — manual reset on next mutation |
| Settings mutation errors invisible to user | Medium | Medium | Settings page doesn't observe error.value |

### Architecture Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Workflow Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Technical Debt Introduced

| Debt | Impact | Status |
|---|---|---|
| mutationError signal separate from error signal | Low | Acceptable — prevents regression, can consolidate later |
| No auto-reset for mutation state | Low | Acceptable — manual reset on next mutation |

### Recommendations

1. Add unit tests for mutation failure paths (highest priority)
2. Consider auto-reset for mutationError after 3 seconds
3. Add UI surface for settings mutation errors (snackbar or inline)

---

## B2 Product Maturity — Audit

### Accepted Work

| Item | Status | Notes |
|---|---|---|
| Thesis dialog (10 fields) | ✅ Accepted | All fields from CompanyThesis model now capturable |
| Exit price in close dialog | ✅ Accepted | Enables P&L calculation for closed positions |
| Thesis → Position bridge | ✅ Accepted | Full bridge: selector in dialog + button on thesis cards |
| PortfolioProvider naming fix | ✅ Accepted | Workspace variant renamed to PortfolioWorkspaceProvider |
| Position return calculation | ✅ Accepted | returnPercent computed property + badge display |
| Lessons aggregation view | ✅ Accepted | Grouped by outcome with summary chips |

### Rejected Work

| Item | Reason |
|---|---|
| None | All proposed work accepted |

### Concerns

| Concern | Severity | Status |
|---|---|---|
| Inline Supabase query in Add Position dialog | Medium | Bypasses repository pattern — should refactor later |
| Thesis selector adds complexity to dialog | Low | Optional field — user can skip |
| Lessons view has no filtering/search | Low | Deferred — can add in future iteration |

### Risk Areas

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Thesis selector fetches on every company selection | Low | Low | Query is lightweight (5 theses max) |
| Return calculation assumes both prices exist | Low | Low | Null-safe — returns null if either missing |

### Architecture Violations

| Violation | Severity | Status |
|---|---|---|
| Direct Supabase query in Add Position dialog | Medium | Deferred — should use repository pattern |

### Workflow Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Technical Debt Introduced

| Debt | Impact | Status |
|---|---|---|
| Inline Supabase query in dialog | Medium | Should refactor to repository |
| _StanceChipSmall duplicate of _StanceBadge | Low | Should deduplicate |

### Recommendations

1. Refactor Add Position dialog to use repository pattern
2. Deduplicate stance/conviction chip widgets
3. Add filtering/search to lessons aggregation view

---

## B3 Data Trust Layer — Audit

### Accepted Work

| Item | Status | Notes |
|---|---|---|
| QualityScoreDetail model | ✅ Accepted | 7 component scores + component_details |
| Quality breakdown popover | ✅ Accepted | Shows all components with progress bars |
| Tappable quality badge | ✅ Accepted | QualityBreakdownTooltip wraps badge |
| DATA TRUST section in overview | ✅ Accepted | Quality + freshness badges with scored date |
| Freshness indicators on metrics | ✅ Accepted | 2px colored border + "as of [date]" |
| Restatement indicators in financials | ✅ Accepted | ↺ icon with tooltip |
| Per-column freshness coloring | ✅ Accepted | Green/amber/red based on age |
| Statement version badges | ✅ Accepted | v2, v3, etc. when version > 1 |

### Rejected Work

| Item | Reason |
|---|---|
| None | All proposed work accepted |

### Concerns

| Concern | Severity | Status |
|---|---|---|
| Quality breakdown popover uses showMenu (not ideal for complex content) | Low | Works but could use Overlay for better positioning |
| Per-metric freshness depends on scoreDate (same for all metrics) | Low | Individual metric freshness not yet available |

### Risk Areas

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Quality breakdown popover may overflow on small screens | Low | Low | Fixed width 320px — scrollable if needed |
| Freshness coloring based on periodEnd age (not data age) | Low | Low | Close enough for now — per-metric freshness later |

### Architecture Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Workflow Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Technical Debt Introduced

| Debt | Impact | Status |
|---|---|---|
| Per-metric freshness uses scoreDate (not individual metric dates) | Low | Acceptable — can enhance later |

### Recommendations

1. Consider using Overlay instead of showMenu for popover
2. Add per-metric freshness when backend supports it
3. Add quality trend indicator (improving/declining)

---

## B5 Performance & Scale — Audit

### Accepted Work

| Item | Status | Notes |
|---|---|---|
| --wasm flag in deploy workflow | ✅ Accepted | Critical for WebAssembly compilation |
| RepaintBoundary on price cells | ✅ Accepted | Highest-impact rendering fix |
| itemExtent on ListView.builder | ✅ Accepted | Eliminates per-child measurement passes |
| compute() offloading for getTopMovers | ✅ Accepted | Prevents main thread blocking |

### Rejected Work

| Item | Reason |
|---|---|
| None | All proposed work accepted |

### Concerns

| Concern | Severity | Status |
|---|---|---|
| itemExtent may clip variable-height content | Low | Content uses maxLines + ellipsis — safe |
| compute() adds isolate overhead for small payloads | Low | 200 rows is worth the overhead |

### Risk Areas

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| --wasm flag may break some packages | Low | High | Test build before deploying |
| RepaintBoundary adds compositing layers | Low | Low | Worth the trade-off for granular repaints |

### Architecture Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Workflow Violations

| Violation | Severity | Status |
|---|---|---|
| None identified | — | — |

### Technical Debt Introduced

| Debt | Impact | Status |
|---|---|---|
| None | — | — |

### Recommendations

1. Test --wasm build before deploying
2. Monitor RepaintBoundary layer count in debug mode
3. Consider compute() for other heavy JSON mappings (portfolio, company)

---

*This log is maintained by the Reviewer Agent. Build may NOT write this file.*
