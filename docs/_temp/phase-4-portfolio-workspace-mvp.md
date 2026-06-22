# Phase 4 — Portfolio Workspace MVP

**Date:** 2026-06-20
**Type:** Design document — no implementation
**Perspective:** Product Designer + Investment Analyst

---

## Purpose

Portfolio Workspace answers:

**"What decisions have I made, and are they still valid?"**

It tracks investment decisions — not prices, not P&L, not broker activity.

---

## Product Philosophy

Portfolio Workspace is a **decision journal**, not a portfolio tracker.

It exists to:
- Record which research became investment decisions
- Track whether decisions are still valid
- Surface positions that need review
- Connect positions to the research that justified them

It does NOT exist to:
- Show real-time prices
- Calculate P&L
- Manage orders
- Report taxes
- Display charts

---

## User Workflows

### Workflow 1: Record a Decision

```
User has thesis on Company X
→ Decides to invest
→ Opens Portfolio Workspace
→ "Add Position"
→ Links to existing thesis
→ Records entry date, entry price, conviction
→ Position appears in Portfolio
```

### Workflow 2: Review Positions

```
User opens Portfolio Workspace
→ Sees all positions
→ Identifies positions with "stale" theses
→ Clicks into Company Workspace
→ Reviews thesis, updates if needed
→ Returns to Portfolio
```

### Workflow 3: Close a Position

```
User decides to sell
→ Opens position
→ "Close Position"
→ Records outcome (correct/incorrect/partial)
→ Records lessons learned
→ Position moves to "Closed" history
```

### Workflow 4: Learn from History

```
User opens "Closed" tab
→ Reviews past decisions
→ Identifies patterns (what worked, what didn't)
→ Improves future research
```

---

## Information Architecture

```
Portfolio Workspace
├── Active Positions
│   ├── Position Card
│   │   ├── Company
│   │   ├── Thesis (linked)
│   │   ├── Conviction
│   │   ├── Entry Date
│   │   ├── Entry Price
│   │   └── Actions: Edit, Close
│   └── Summary Bar
│       ├── Total positions
│       ├── Conviction distribution
│       └── Sector distribution
├── Closed Positions
│   ├── Position Card
│   │   ├── Company
│   │   ├── Original Thesis
│   │   ├── Outcome (correct/incorrect/partial)
│   │   ├── Entry/Exit Date
│   │   ├── Entry/Exit Price
│   │   └── Lessons Learned
│   └── Summary Bar
│       ├── Total closed
│       └── Success rate
└── Decision Journal
    ├── Recent Activity
    └── Decision Log
```

---

## Portfolio Lifecycle

```
Research → Thesis → Conviction → Position → Monitor → Close → Learn
   ↑          ↑         ↑           ↑          ↑         ↑       ↑
Companies  Company   Company    Portfolio   Portfolio  Portfolio Portfolio
Workspace  Workspace Workspace  Workspace   Workspace Workspace Workspace
```

### Status Lifecycle

| Status | Meaning | Trigger |
|---|---|---|
| Active | Position is held | User creates position |
| Reviewing | Thesis needs attention | Manual or stale thesis |
| Closed | Position exited | User closes position |

---

## Data Model

### Position

| Field | Type | Required | Purpose |
|---|---|---|---|
| id | UUID | auto | Primary key |
| user_id | UUID | yes | Owner |
| company_id | UUID | yes | Company reference |
| thesis_id | UUID | no | Linked thesis |
| conviction | enum | yes | low/medium/high |
| entry_date | date | yes | When position opened |
| entry_price | numeric | no | Price at entry |
| status | enum | yes | active/reviewing/closed |
| exit_date | date | no | When position closed |
| exit_price | numeric | no | Price at exit |
| outcome | enum | no | correct/incorrect/partial |
| notes | text | no | Decision notes |
| created_at | timestamp | auto | Record creation |
| updated_at | timestamp | auto | Last update |

### Key Decisions

- **No P&L calculation.** Portfolio tracks decisions, not returns.
- **No real-time prices.** Entry/exit prices are user-provided.
- **No broker integration.** All data is manual.
- **Thesis linking is optional.** Some positions may not have a formal thesis.

---

## UX Layout

### Active Positions Tab

```
┌─────────────────────────────────────────────────────────────────┐
│ Portfolio                                        [+ Add Position]│
├─────────────────────────────────────────────────────────────────┤
│ Summary                                                         │
│ ┌──────────┬──────────┬──────────┐                              │
│ │ Positions│ Convic.  │ Sectors  │                              │
│ │ 5 active │ 3H · 2M  │ 4        │                              │
│ └──────────┴──────────┴──────────┘                              │
│                                                                 │
│ Positions                                                       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ NVIDIA Corp (NVDA)                                          │ │
│ │ Bullish · High Conviction · Entry: $450 · Jun 2025          │ │
│ │ Thesis: AI demand drives sustained growth                   │ │
│ │ [View] [Edit] [Close]                                       │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ Apple Inc. (AAPL)                                            │ │
│ │ Bullish · High Conviction · Entry: $150 · Jun 2025          │ │
│ │ Thesis: Services revenue compounds                          │ │
│ │ [View] [Edit] [Close]                                       │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Closed Positions Tab

```
┌─────────────────────────────────────────────────────────────────┐
│ Closed Positions                                                │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Tesla Inc. (TSLA)                                           │ │
│ │ Entry: $200 · Exit: $180 · Outcome: Incorrect               │ │
│ │ Original Thesis: EV adoption thesis                         │ │
│ │ Lesson: Overestimated competition impact                    │ │
│ │ [View Details]                                              │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## MVP Scope

### MUST HAVE

| Feature | Rationale |
|---|---|
| Active positions list | Core view |
| Add position (company, thesis, conviction, entry date) | Core action |
| Close position (outcome, notes) | Core lifecycle |
| Closed positions history | Learning |
| Company/thesis linkage | Research integration |
| Empty states | Guidance |

### SHOULD HAVE

| Feature | Rationale |
|---|---|
| Conviction badges | Visual clarity |
| Sector summary | Diversification context |
| Quick "View Company" navigation | Workflow integration |

### DO NOT BUILD

| Feature | Reason |
|---|---|
| P&L calculation | Not a portfolio tracker |
| Real-time prices | Not a trading platform |
| Charts | Post-MVP |
| Sector allocation charts | Post-MVP |
| Benchmark comparison | Post-MVP |
| Export | Post-MVP |
| Multiple portfolios | Future |

---

## Deferred Features

| Feature | When | Why |
|---|---|---|
| P&L display | Post-MVP | Requires price data integration |
| Sector allocation chart | Post-MVP | Visual enhancement |
| Benchmark comparison | Post-MVP | Requires index data |
| Multiple portfolios | Future | User segmentation |
| Decision journal timeline | Post-MVP | UX enhancement |

---

## Recommendation

1. **Portfolio is a decision journal.** Track decisions, not prices.
2. **Thesis linking is core.** Every position should reference a thesis.
3. **Close workflow is essential.** Learning from decisions is the value.
4. **No P&L.** That's a portfolio tracker, not a research workspace.
5. **Keep it simple.** Position list + close workflow + history.
