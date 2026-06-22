# C4.1 — MVP Refinement Review

**Date:** 2026-06-20
**Type:** MVP refinement — no implementation
**Perspective:** Product Manager + Solo Builder + Staff Engineer

---

## Executive Summary

The C4 MVP definition is 85% correct. Five refinements are needed: (1) Research Queue becomes MUST HAVE, (2) Close Position becomes MUST HAVE, (3) Thesis Snapshot is added to Overview tab, (4) delivery estimate is revised from 29 to 40-50 days, (5) a Phase 0 foundation sprint is added. The core loop (Discover → Research → Decide → Track → Learn) now has no gaps.

---

## MVP Scope Review

### Revised Classification

| Feature | C4 Classification | C4.1 Classification | Reason |
|---|---|---|---|
| Company list | MUST HAVE | MUST HAVE | Entry point |
| Company Workspace (Overview) | MUST HAVE | MUST HAVE | Core research |
| Company Workspace (Financials) | MUST HAVE | MUST HAVE | Core research |
| Company Workspace (Research tab) | MUST HAVE | MUST HAVE | Core research |
| Research notes (company-scoped) | MUST HAVE | MUST HAVE | Core workflow |
| Investment theses | MUST HAVE | MUST HAVE | Core workflow |
| Conviction tracking | MUST HAVE | MUST HAVE | Core workflow |
| Portfolio positions | MUST HAVE | MUST HAVE | Core workflow |
| Quality badge | MUST HAVE | MUST HAVE | Trust |
| Freshness badge | MUST HAVE | MUST HAVE | Trust |
| Settings | MUST HAVE | MUST HAVE | Configuration |
| **Research Queue** | SHOULD HAVE | **MUST HAVE** | Natural discovery entry point |
| **Close Position** | SHOULD HAVE | **MUST HAVE** | Required for "Learn" workflow |
| **Thesis Snapshot in Overview** | — | **SHOULD HAVE** | Quick thesis context |
| Source badge | SHOULD HAVE | SHOULD HAVE | Attribution |
| Entry date/price | SHOULD HAVE | SHOULD HAVE | Position context |
| General notes | DEFER | DEFER | Company-scoped sufficient |
| Collections | DEFER | DEFER | Tags are future |
| Dashboard | DEFER | DEFER | Not core workflow |
| Screener | DEFER | DEFER | Discovery, not research |
| Comparison | DEFER | DEFER | Decision support |
| Data workspace | DEFER | DEFER | Trust detail |

---

## Research Queue Evaluation

### Why Research Queue Becomes MUST HAVE

**Without Research Queue:**
- User discovers a company via external source
- User has nowhere to record "I want to research this"
- The discovery → research gap has no bridge

**With Research Queue:**
- User adds company to Research Queue
- User opens Research Queue → sees list of companies to research
- User clicks company → Company Workspace → research begins

### Research Queue MVP Behavior

```
Research Queue
├── List of companies to research
├── Add company (from Company List)
├── Remove company (when research complete)
├── Company entry shows: name, ticker, quality badge
└── Click → opens Company Workspace
```

### Implementation Impact

Minimal. Research Queue is a named watchlist. The watchlist infrastructure already exists in the database (`watchlists`, `watchlist_items`). Research Queue is just a default watchlist.

---

## Position Lifecycle Evaluation

### Why Close Position Becomes MUST HAVE

**Without Close Position:**
- User opens position
- Position stays "active" forever
- No outcome recording
- No learning from decisions
- The "Learn" step has no implementation

**With Close Position:**
- User closes position
- Records outcome (correct/incorrect/partial)
- Records lessons learned
- Can review past decisions

### Close Position MVP Behavior

```
Close Position
├── Confirm close
├── Record outcome: Correct / Incorrect / Partially Correct
├── Record notes: "What happened? What did I learn?"
├── Status changes: Active → Closed
└── Closed positions visible in separate view
```

### Implementation Impact

Moderate. Requires:
- Close position dialog
- Outcome selector (correct/incorrect/partial)
- Notes field
- Status change logic
- Closed positions list view

---

## Thesis Snapshot Evaluation

### Why Thesis Snapshot is SHOULD HAVE

**Without Thesis Snapshot:**
- User opens Company Workspace → Overview tab
- Sees metrics, filings, quality
- Must navigate to Research tab to see thesis status
- Context switch interrupts flow

**With Thesis Snapshot:**
- User opens Company Workspace → Overview tab
- Sees metrics AND thesis summary in one view
- Quick context: "I'm bullish, high conviction, last updated 2 days ago"

### Thesis Snapshot MVP Behavior

```
┌─────────────────────────────────────┐
│ My Thesis                           │
│ NVIDIA — Bullish 🟢 High Conviction │
│ Updated: 2026-06-15                 │
│ [View Full Thesis]                  │
└─────────────────────────────────────┘
```

### Implementation Impact

Minimal. Just a small card in the Overview tab that reads from the existing thesis data.

---

## Delivery Estimate Review

### Why 29 Days is Optimistic

The C4 estimate assumed:
- Each task takes its "ideal" time
- No integration surprises
- No design iteration
- No Flutter Web quirks

### Realistic Adjustments

| Factor | Impact | Days Added |
|---|---|---|
| Flutter Web quirks | WASM compilation, responsive layout, browser quirks | +3 days |
| Supabase integration | RLS, auth flow, data fetching patterns | +2 days |
| Design system primitives | Badges, cards, tables need implementation | +3 days |
| Routing setup | go_router nested routes, deep linking | +1 day |
| Testing + debugging | Always more than expected | +5 days |
| Polish + edge cases | Empty states, error handling, loading states | +3 days |
| **Total adjustment** | | **+17 days** |

### Revised Estimate: 40-50 focused days

With part-time availability (~3-4 hours/day), this is approximately **12-16 weeks**.

---

## Revised Delivery Plan

### Phase 0: Foundation (Week 1-2)

| Task | Days | Rationale |
|---|---|---|
| App shell (navigation, layout) | 2 | All pages share this |
| Design system primitives (badges, cards, tables) | 2 | Reused everywhere |
| Supabase client setup | 1 | Data layer foundation |
| Routing skeleton | 1 | All pages need routes |
| Empty state components | 1 | Every page needs empty state |
| **Total** | **7** | |

### Phase 1: Company Workspace (Week 3-5)

| Task | Days | Rationale |
|---|---|---|
| Company list page | 1 | Entry point |
| Company workspace page | 1 | Container for tabs |
| Overview tab (metrics + summary) | 2 | First thing users see |
| Financials tab (statements) | 2 | Core research |
| Research tab (notes list) | 1 | Links to Phase 2 |
| Quality + freshness badges | 1 | Trust layer |
| **Total** | **8** | |

### Phase 2: Research Workflow (Week 6-8)

| Task | Days | Rationale |
|---|---|---|
| Note editor (plain text) | 1 | Core research activity |
| Note CRUD | 1 | Create/edit/delete |
| Thesis form | 2 | Structured thinking |
| Conviction selector | 0.5 | Quick interaction |
| Research Queue (default watchlist) | 1 | Discovery → research bridge |
| Thesis snapshot in Overview | 0.5 | Quick context |
| Research page (notes + theses list) | 1 | Aggregated view |
| **Total** | **7** | |

### Phase 3: Portfolio + Lifecycle (Week 9-10)

| Task | Days | Rationale |
|---|---|---|
| Portfolio page | 2 | Position tracking |
| Position creation (link thesis) | 1 | Decision recording |
| Close position workflow | 1.5 | Learning from decisions |
| Outcome recording | 0.5 | Correct/incorrect/partial |
| Closed positions view | 0.5 | History review |
| Settings page | 1 | Configuration |
| **Total** | **6.5** | |

### Phase 4: Polish + Deploy (Week 11-12)

| Task | Days | Rationale |
|---|---|---|
| Responsive layout | 2 | Desktop + tablet |
| Loading states | 1 | UX polish |
| Error handling | 1 | Robustness |
| Keyboard navigation | 0.5 | Desktop UX |
| Vercel deployment | 1 | Go live |
| Testing + bug fixes | 3 | Always needed |
| **Total** | **8.5** | |

### Total: ~29.5 focused days → ~40-50 real days

---

## Remaining Risks

### Scope Creep

**Risk:** "Just one more feature" delays MVP indefinitely.

**Mitigation:** This document is the scope contract. Any addition requires removing something of equal effort.

### Flutter Web Table Performance

**Risk:** Financial statement tables with 50+ rows may be slow on Web.

**Mitigation:** Use `ListView.builder` with fixed `itemExtent`. Test early with real data.

### Supabase RLS Complexity

**Risk:** RLS policies for notes/theses may have edge cases.

**Mitigation:** Test RLS policies early. Use service_role for workers, authenticated for user data.

### Design System Drift

**Risk:** UI looks inconsistent because design system is not enforced.

**Mitigation:** Phase 0 establishes primitives. All phases use them.

### Motivation / Burnout

**Risk:** 12-16 weeks of part-time work is a long commitment.

**Mitigation:** Each phase delivers usable features. Incremental progress keeps motivation high.

---

## Recommendation

1. **Accept refined scope.** Research Queue + Close Position are MUST HAVE.

2. **Add Phase 0.** Foundation sprint prevents rework.

3. **Revised timeline: 12-16 weeks.** More realistic for solo developer.

4. **Thesis Snapshot is cheap.** Add it to Overview tab.

5. **Stay ruthless.** No new features until MVP ships.
