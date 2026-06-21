# TAUG Disagreement Log

**Created:** 2026-06-21
**Purpose:** Record all significant disagreements. Healthy teams disagree.

---

## Disagreement 1: MutationState Pattern Complexity

**Phase:** B1.1
**Issue:** How to implement mutation feedback — 28 per-mutation signals vs simple error propagation

**Position A (Plan Agent):**
- Create `MutationState<T>` sealed class
- Add 28 per-mutation signals across 6 providers
- Complete state tracking per mutation
- Future-proof for concurrent mutations

**Position B (God-1, Reviewer):**
- Simple `error.value` propagation
- `_isMutating` guards for race conditions
- No new abstractions in a hotfix
- Fix the actual bug (silent failures)

**Who Supported A:** Plan Agent
**Who Supported B:** God-1, Reviewer

**Reviewer Position:** Strongly supported Position B. Identified that both plans miss the root cause — mutations silently swallow failures. "Hotfixes should fix bugs, not add architecture."

**Build Decision:** Accepted Position B
**Outcome:** 17 mutations fixed with simple error propagation. No new abstractions introduced.

**Lessons Learned:**
- Reviewer challenge is valuable — caught over-engineering
- Hotfix scope should be minimal and focused
- Existing infrastructure (Failure types) should be used before creating new ones
- "Future-proofing" is not a valid reason to over-engineer a hotfix

---

## Disagreement 2: Dialog Behavior on Failure

**Phase:** B1.1
**Issue:** Should dialogs stay open or close on mutation failure?

**Position A (Plan Agent):**
- All dialogs stay open on failure
- Show inline error message
- Retry capability

**Position B (God-1):**
- Split by mutation type:
  - Forms stay open (preserve user input)
  - Confirmations close with snackbar
  - Settings revert with snackbar

**Who Supported A:** Plan Agent
**Who Supported B:** God-1, Reviewer

**Reviewer Position:** Supported Position B with evidence from Bloomberg/professional terminals.

**Build Decision:** Accepted Position B
**Outcome:** Implemented split pattern for watchlist delete confirmation. Forms stay open, confirmations close.

**Lessons Learned:**
- Different mutation types need different UX patterns
- Form data preservation is critical for research workflow
- Professional terminal patterns are good references

---

## Disagreement 3: Quality Score Granularity

**Phase:** B3
**Issue:** How much quality detail to fetch and display?

**Position A (Plan Agent):**
- Fetch all 7 component scores + component_details
- Show full breakdown in popover
- Maximum transparency

**Position B (God-2):**
- Fetch only overall_score + freshness_score
- Simpler UI
- Less data to process

**Who Supported A:** Plan Agent
**Who Supported B:** God-2

**Reviewer Position:** Supported Position A. "A quality score of '65%' is meaningless without context."

**Build Decision:** Accepted Position A
**Outcome:** QualityScoreDetail model with 7 scores. QualityBreakdownPopover widget. Tappable quality badge.

**Lessons Learned:**
- Data trust requires granularity
- Users need to understand the WHY behind scores
- Backend already stores all components — just wire them up

---

## Disagreement 4: Thesis → Position Bridge Scope

**Phase:** B2
**Issue:** How to implement the Research → Portfolio connection?

**Position A (Plan Agent):**
- Thesis selector in Add Position dialog only
- Simpler implementation
- One entry point

**Position B (God-3):**
- Full bridge: thesis selector + "Create Position" button on thesis cards
- Two entry points for different contexts
- Maximum workflow connectivity

**Who Supported A:** Plan Agent
**Who Supported B:** God-3

**Reviewer Position:** Strongly supported Position B. "This is the single most important missing piece in the entire product."

**Build Decision:** Accepted Position B
**Outcome:** Full bridge implemented. Thesis selector in dialog + button on thesis cards.

**Lessons Learned:**
- Workflow connectivity is critical for Research OS
- Multiple entry points serve different user contexts
- The "Decision" step in the workflow is where thesis becomes action

---

## Disagreement 5: Performance Optimization Scope

**Phase:** B5
**Issue:** How many performance issues to fix in B5?

**Position A (Plan Agent):**
- Fix --wasm flag only (minimal)
- Lower risk
- Faster completion

**Position B (Perf Agent):**
- Fix all identified issues:
  - --wasm flag
  - RepaintBoundary
  - itemExtent
  - compute() offloading

**Who Supported A:** Plan Agent
**Who Supported B:** Perf Agent, Build Orchestrator

**Reviewer Position:** Supported Position B. "Performance is critical for a financial terminal."

**Build Decision:** Accepted Position B
**Outcome:** All performance issues fixed in parallel with 4 agents.

**Lessons Learned:**
- Performance is non-negotiable for financial terminals
- Parallel delegation makes large scopes manageable
- All optimizations compile together without conflicts

---

## Disagreement 6: Agent Delegation Strategy

**Phase:** B3, B5
**Issue:** Sequential vs parallel implementation?

**Position A (Conservative):**
- Sequential implementation
- One agent at a time
- Lower risk of conflicts

**Position B (Aggressive):**
- Parallel delegation
- Multiple agents simultaneously
- Faster completion

**Who Supported A:** None (not proposed)
**Who Supported B:** Build Orchestrator

**Reviewer Position:** No challenge (unanimous agreement)

**Build Decision:** Accepted Position B
**Outcome:** 7 agents delegated in parallel across B3 and B5. All changes compiled successfully.

**Lessons Learned:**
- Independent tasks can be parallelized safely
- Need to verify all changes compile together
- Parallel delegation maximizes throughput
- File-level isolation prevents conflicts

---

*This log is continuously updated throughout execution. If it remains empty, the review process is likely ineffective.*
