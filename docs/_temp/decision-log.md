# TAUG Decision Log

**Created:** 2026-06-21
**Purpose:** Record every meaningful decision with context, options, and reasoning.

---

## Decision 1: Use MutationState Pattern vs Simple Error Propagation

**Date:** 2026-06-21
**Phase:** B1.1
**Context:** 17 mutation methods silently swallow failures. Users get zero feedback when operations fail.

**Options Considered:**
1. Create `MutationState<T>` sealed class with 28 per-mutation signals
2. Simple `error.value` propagation with `_isMutating` guards
3. MutationState with 1 signal per provider (6 total)

**Proposed By:** Plan Agent
**Challenged By:** God-1, Reviewer

**Arguments For (Option 1):**
- Complete state tracking per mutation
- Type-safe error handling
- Future-proof for concurrent mutations

**Arguments Against (Option 1):**
- 28 new signals is over-engineered
- UI is modal — only 1 mutation runs at a time per provider
- Maintenance burden outweighs benefit
- Builds on dead infrastructure (Failure types unused)

**Arguments For (Option 2):**
- Minimal changes, maximum impact
- Fixes the actual bug (silent failures)
- No new abstractions in a hotfix
- Can upgrade later if needed

**Arguments Against (Option 2):**
- Less granular state tracking
- Error signal overloaded with read errors

**Final Decision:** Option 2 (Simple error propagation)
**Decision Owner:** Build Orchestrator
**Reasoning:** Reviewer correctly identified that both plans miss the root cause — mutations silently swallow failures. The hotfix should fix bugs, not add architecture. MutationState can be added in B1.2 if needed.
**Consequences:**
- 17 mutations now propagate errors with debugPrint
- `_isMutating` guards prevent double-submit
- Stale errors cleared before each mutation
- Separate `mutationError` signal for WorkspaceProvider to avoid full-page error regression

---

## Decision 2: Dialog Behavior on Mutation Failure

**Date:** 2026-06-21
**Phase:** B1.1
**Context:** Dialogs close immediately on fire-and-forget mutations, even on failure.

**Options Considered:**
1. All dialogs stay open on failure
2. All dialogs close with error snackbar
3. Split by mutation type (forms stay open, confirmations close)

**Proposed By:** God-1
**Challenged By:** Reviewer

**Arguments For (Option 3):**
- Form data is sacred — never discard user input on transient network error
- Confirmation dialogs have no data to preserve — close with snackbar
- Settings toggles — revert UI state, show snackbar

**Arguments Against (Option 3):**
- More complex implementation
- Two patterns to maintain

**Final Decision:** Option 3 (Split by mutation type)
**Decision Owner:** Build Orchestrator
**Reasoning:** Bloomberg and professional terminals use this pattern. Form data preservation is critical for research workflow.
**Consequences:**
- `_showDeleteConfirmation` now awaits mutation and checks error before closing
- `_AddHoldingDialog` stays open on failure (not yet implemented)
- Settings toggles revert on failure (not yet implemented)

---

## Decision 3: Thesis Dialog Field Completeness

**Date:** 2026-06-21
**Phase:** B2
**Context:** CompanyThesis model has 10 fields but dialog only captures 6.

**Options Considered:**
1. Add all 4 missing fields (assumptions, catalysts, risks, exitConditions)
2. Consolidate fields (e.g., "risks & assumptions" as one)
3. Keep dialog minimal, add fields later

**Proposed By:** Plan Agent
**Challenged By:** God-3

**Arguments For (Option 1):**
- These fields are critical for Research → Decision workflow
- Without them, thesis is just a summary with stance
- Model already has the fields — just wire them up

**Arguments Against (Option 1):**
- Dialog becomes more complex
- More fields = more friction to create thesis

**Final Decision:** Option 1 (Add all 4 missing fields)
**Decision Owner:** Build Orchestrator
**Reasoning:** The difference between a "note" and a structured investment thesis is these fields. Research → Decision transition requires structured thinking.
**Consequences:**
- Thesis dialog now captures all 10 fields
- ThesisCard displays all populated sections
- All fields optional except title, stance, conviction

---

## Decision 4: Thesis → Position Bridge Implementation

**Date:** 2026-06-21
**Phase:** B2
**Context:** Portfolio positions have thesisId but no way to link them in UI.

**Options Considered:**
1. Thesis selector in Add Position dialog
2. "Create Position" button on thesis cards
3. Both (full bridge)

**Proposed By:** God-3
**Challenged By:** Reviewer

**Arguments For (Option 3):**
- Closes the Research → Decision → Portfolio loop
- Two entry points serve different user flows
- Maximum workflow connectivity

**Arguments Against (Option 3):**
- More UI to maintain
- Thesis selector adds complexity to Add Position dialog

**Final Decision:** Option 3 (Full bridge)
**Decision Owner:** Build Orchestrator
**Reasoning:** This is the single most important missing piece in the research workflow. Both entry points are needed for different contexts.
**Consequences:**
- Add Position dialog fetches theses for selected company
- Thesis selector auto-populates conviction
- ThesisCard has "Create Position" button
- Research → Decision → Portfolio workflow is now continuous

---

## Decision 5: PortfolioProvider Naming Collision

**Date:** 2026-06-21
**Phase:** B2
**Context:** Two classes named `PortfolioProvider` in the same feature.

**Options Considered:**
1. Rename workspace variant to `PortfolioWorkspaceProvider`
2. Rename holdings variant to `PortfolioHoldingsProvider`
3. Keep both, use import aliases

**Proposed By:** God-3
**Challenged By:** Reviewer

**Arguments For (Option 1):**
- Workspace variant is the new canonical implementation
- Holdings variant is legacy
- Clear naming indicates purpose

**Arguments Against (Option 1):**
- Breaking change for imports
- Need to update all references

**Final Decision:** Option 1 (Rename workspace variant)
**Decision Owner:** Build Orchestrator
**Reasoning:** The workspace variant is the primary implementation for the research workflow. Clear naming prevents confusion.
**Consequences:**
- `PortfolioWorkspaceProvider` class name
- Updated imports in portfolio_workspace_page.dart
- Legacy holdings provider unchanged

---

## Decision 6: Quality Score Breakdown Granularity

**Date:** 2026-06-21
**Phase:** B3
**Context:** `getQualityScore` only fetches `overall_score`. Users can't understand WHY quality is low.

**Options Considered:**
1. Fetch all 7 component scores + component_details
2. Fetch only overall_score + freshness_score
3. Keep current, add explanation text

**Proposed By:** Plan Agent
**Challenged By:** God-2

**Arguments For (Option 1):**
- Users need to understand the WHY behind quality scores
- Component_details has period_count, item_count, etc.
- Backend already stores all components

**Arguments Against (Option 1):**
- More data to fetch and display
- UI becomes more complex

**Final Decision:** Option 1 (Fetch all components)
**Decision Owner:** Build Orchestrator
**Reasoning:** A quality score of "65%" is meaningless without context. Is it low because of missing data, failed validations, or staleness? Users need the breakdown.
**Consequences:**
- QualityScoreDetail model with 7 scores + component_details
- QualityBreakdownPopover widget
- Tappable quality badge in company header
- 3 micro-commits for implementation

---

## Decision 7: Performance Optimization Priority

**Date:** 2026-06-21
**Phase:** B5
**Context:** Multiple performance issues identified in analysis.

**Options Considered:**
1. Fix --wasm flag only (minimal)
2. Fix --wasm + RepaintBoundary + itemExtent
3. Fix all performance issues (including compute() offloading)

**Proposed By:** Plan Agent
**Challenged By:** Perf Agent

**Arguments For (Option 3):**
- WASM compilation is non-negotiable
- RepaintBoundary on price cells is highest-impact rendering fix
- itemExtent eliminates per-child measurement passes
- compute() offloading prevents main thread blocking

**Arguments Against (Option 3):**
- More changes = more risk
- Some optimizations may not be needed yet

**Final Decision:** Option 3 (Fix all performance issues)
**Decision Owner:** Build Orchestrator
**Reasoning:** Performance is critical for a financial terminal. All identified issues should be fixed before production.
**Consequences:**
- --wasm flag in deploy workflow
- RepaintBoundary on PriceCell, ChangeCell, VolumeCell, StatusDot
- itemExtent on ListView.builder (news: 80px, portfolio: 120px)
- compute() offloading for getTopMovers

---

## Decision 8: Agent Delegation Strategy

**Date:** 2026-06-21
**Phase:** B3, B5
**Context:** Multiple independent tasks can be parallelized.

**Options Considered:**
1. Sequential implementation (one agent at a time)
2. Parallel delegation (multiple agents simultaneously)
3. Mixed (sequential for dependencies, parallel for independent)

**Proposed By:** Build Orchestrator
**Challenged By:** None

**Arguments For (Option 2):**
- Independent tasks can be parallelized
- Faster completion
- Better resource utilization

**Arguments Against (Option 2):**
- More coordination needed
- Potential conflicts if agents modify same files
- Need to verify all changes compile together

**Final Decision:** Option 2 (Parallel delegation)
**Decision Owner:** Build Orchestrator
**Reasoning:** Tasks are independent and touch different files. Parallel delegation maximizes throughput.
**Consequences:**
- B3: 3 agents (frontend-1, frontend-2, god-1) worked in parallel
- B5: 4 agents (devops, frontend-1, frontend-2, backend-1) worked in parallel
- All changes compiled successfully together
- 16 micro-commits total

---

*This log is continuously updated throughout execution.*
