# B7 — Portfolio & Watchlist Architecture

**Date:** 2026-06-20
**Type:** Product design — no implementation
**Perspective:** Long-Term Investor + Research Analyst + Portfolio Manager + Knowledge Worker + Product Designer

---

## Executive Summary

TAUG's Portfolio is a **decision tracker**, not a P&L dashboard. It answers "what did I decide and why?" rather than "how much money did I make today?" The architecture integrates portfolio positions with research theses, conviction tracking, and decision journaling — creating a complete investment lifecycle from discovery to learning.

**Core insight:** The value of a portfolio tracker isn't knowing your returns. It's knowing your reasoning.

---

## Portfolio Philosophy

### What Portfolio Means in TAUG

Portfolio represents **owned companies with active theses**. It's not just a list of tickers — it's a collection of investment decisions, each with a reason, a conviction level, and a monitoring workflow.

### Design Principles

1. **Decisions have reasons.** Every position should have a linked thesis.
2. **Conviction evolves.** Portfolio should track how thinking changes.
3. **Monitoring is research.** Watching a position is an active research activity.
4. **Learning is the goal.** Closed positions should teach lessons.

### What Portfolio Is NOT

- A broker (no trading)
- A P&L dashboard (not primary focus)
- A tax tool (no cost basis tracking)
- A real-time monitor (not intraday)

---

## Portfolio Model

### Entity Relationships

```
Portfolio
├── Positions (owned companies)
│   ├── Company
│   ├── Thesis (linked)
│   ├── Conviction (current level)
│   ├── Entry Date
│   ├── Entry Price
│   ├── Status (active/closed)
│   └── Decision Notes
├── Closed Positions (historical)
│   ├── Company
│   ├── Thesis (original)
│   ├── Entry/Exit Dates
│   ├── Entry/Exit Prices
│   ├── Outcome
│   └── Lessons Learned
└── Portfolio Metrics
    ├── Sector Allocation
    ├── Conviction Distribution
    ├── Thesis Health
    └── Freshness Status
```

### Position Lifecycle

```
Research → Thesis → Conviction → Position → Monitor → Close → Learn
```

### Key Distinction: Position vs Holding

| Concept | Definition | TAUG Usage |
|---|---|---|
| Holding | A ticker you own | Legacy concept |
| Position | An investment decision with thesis | TAUG concept |

A **position** is richer than a holding. It includes:
- Why you bought
- When you bought
- How confident you are
- What would make you sell

---

## Watchlist Philosophy

### Distinction: Watchlist vs Portfolio

| Concept | Purpose | Contents |
|---|---|---|
| Research Queue | "Companies to research" | Screener hits, ideas |
| Watchlist | "Companies I'm monitoring" | Interesting, not yet owned |
| Portfolio | "Companies I own" | Active positions with theses |
| High Conviction | "Strongest ideas" | Companies with high conviction |

### Watchlist Lifecycle

```
Discover → Research Queue → Research → Watchlist → Thesis → Portfolio
```

### Avoiding Overlap

- **Research Queue** = pre-research (screener hits)
- **Watchlist** = post-research, pre-decision (monitoring)
- **Portfolio** = post-decision (owned)
- **High Conviction** = subset of portfolio (strongest theses)

---

## Portfolio Workspace

### Purpose

The Portfolio page answers: "What do I own, why do I own it, and what's changed?"

### Layout

```
┌─────────────────────────────────────────────────────┐
│ Portfolio                                            │
├─────────────────────────────────────────────────────┤
│ Summary Bar                                          │
│ Positions: 5  │  Conviction: 3 High, 2 Medium  │    │
│ Sectors: 4    │  Freshness: 4 Fresh, 1 Aging   │    │
├─────────────────────────────────────────────────────┤
│ Positions                                            │
├────────┬────────┬────────┬────────┬────────┬────────┤
│ Company│ Sector │ Thesis │ Convic │ Entry  │ Status │
├────────┼────────┼────────┼────────┼────────┼────────┤
│ AAPL   │ Tech   │ Bull 🟢│ High   │ $150   │ Fresh  │
│ NVDA   │ Tech   │ Bull 🟢│ High   │ $450   │ Fresh  │
│ KO     │ Staples│ Bull 🟠│ Medium │ $55    │ Fresh  │
│ JPM    │ Fin    │ Neutral│ Low    │ $180   │ Aging  │
│ XOM    │ Energy │ Bull 🟠│ Medium │ $95    │ Fresh  │
├────────┴────────┴────────┴────────┴────────┴────────┤
│ [Add Position] [View Closed] [Portfolio Dashboard]   │
└─────────────────────────────────────────────────────┘
```

### Primary Actions

1. **View position** → Position detail
2. **Update conviction** → Quick conviction change
3. **Add position** → Link to thesis
4. **View dashboard** → Portfolio health

### Secondary Actions

1. **Close position** → Decision journal
2. **View closed positions** → Learning history
3. **Export portfolio** → Data export

### Success Criteria

- User can see all positions with thesis status in 5 seconds
- User can identify which positions need attention in 10 seconds
- User can update conviction in 3 clicks

---

## Position Tracking

### Position Data Model

| Field | Type | Purpose |
|---|---|---|
| company_id | UUID | Company reference |
| thesis_id | UUID | Linked thesis |
| conviction | enum | Low/Medium/High |
| entry_date | date | When position was opened |
| entry_price | numeric | Price at entry |
| status | enum | Active/Closed |
| decision_notes | text | Why this position was opened |
| created_at | timestamp | Record creation |
| updated_at | timestamp | Last update |

### What Should Be Tracked

| Data | Track? | Rationale |
|---|---|---|
| Entry date | ✅ | Time in position matters |
| Entry price | ✅ | Performance context |
| Thesis link | ✅ | Why you own it |
| Conviction | ✅ | How confident you are |
| Decision notes | ✅ | Context for future review |
| Current price | ❌ | Not primary (market data handles this) |
| P&L | ❌ | Not primary (research focus) |
| Cost basis | ❌ | Tax tool, not research tool |

### Position Detail View

```
┌─────────────────────────────────────────────┐
│ Apple Inc. (AAPL)                           │
│ Technology · Consumer Electronics           │
├─────────────────────────────────────────────┤
│ Position                                    │
│ Entry: 2025-06-15 @ $150.00                │
│ Conviction: High 🟢                         │
│ Status: Active                              │
├─────────────────────────────────────────────┤
│ Thesis: Apple Ecosystem Thesis              │
│ "Services revenue compounds at 15%+.       │
│  iPhone installed base drives recurring     │
│  revenue. Current valuation reasonable."    │
├─────────────────────────────────────────────┤
│ Decision Notes                              │
│ "Bought after Q1 2025 earnings beat.        │
│  Services growth thesis validated."         │
├─────────────────────────────────────────────┤
│ Recent Activity                             │
│ • Updated conviction: Medium → High         │
│   Reason: "Q1 2026 services +18% YoY"      │
│ • Added note: "AI integration thesis"       │
├─────────────────────────────────────────────┤
│ [Edit Position] [Close Position] [View Thesis]│
└─────────────────────────────────────────────┘
```

---

## Thesis Monitoring

### What Changed?

Portfolio should surface changes that affect thesis validity:

| Change Type | Detection | Action |
|---|---|---|
| Valuation changed | PE/PB moved > 20% | Alert |
| Conviction changed | User updated | Record |
| Thesis invalidated | User marks invalid | Close position |
| Freshness degraded | Data becomes stale | Warning |
| Quality degraded | Quality score drops | Warning |
| New filing available | SEC filing ingested | Notification |

### Monitoring Workflow

```
1. Open Portfolio
2. See alerts: "AAPL PE changed from 30 to 39"
3. Review: Is thesis still valid?
4. Update conviction if needed
5. Add note: "Valuation stretched but thesis intact"
```

### Alert Design

```
┌─────────────────────────────────────────────┐
│ Portfolio Alerts                             │
├─────────────────────────────────────────────┤
│ 🟡 AAPL: PE increased 30% (25 → 39)        │
│    Last updated: 2026-06-15                 │
│    [Review] [Dismiss]                       │
├─────────────────────────────────────────────┤
│ 🔴 JPM: Data freshness degraded             │
│    Last filing: 2025-12-31 (stale)          │
│    [Review] [Dismiss]                       │
├─────────────────────────────────────────────┤
│ 🟢 NVDA: New 10-Q filing available          │
│    Filed: 2026-05-15                        │
│    [Review] [Dismiss]                       │
└─────────────────────────────────────────────┘
```

---

## Watchlist System

### Default Watchlists

| Name | Purpose | Auto-populated? |
|---|---|---|
| Research Queue | "Companies to research" | Yes (screener hits) |
| Watchlist | "Companies I'm monitoring" | Manual |
| High Conviction | "Strongest theses" | Yes (conviction = High) |

### Custom Watchlists

Users create named watchlists:
- "AI Companies"
- "Dividend Aristocrats"
- "Turnaround Stories"
- "ASEAN Exposure"

### Watchlist Item Properties

| Field | Type | Purpose |
|---|---|---|
| company_id | UUID | Company reference |
| added_at | date | When added |
| notes | text | Why added |
| priority | enum | Low/Medium/High |
| status | enum | Active/Archived |

### Watchlist vs Portfolio Transition

```
Watchlist → Thesis → Conviction → Portfolio
```

When a watchlist company gets a thesis and conviction, it can become a portfolio position.

---

## Portfolio Dashboard

### What Belongs on Dashboard

| Section | Content | Purpose |
|---|---|---|
| Position Summary | Count, sectors, conviction | Overview |
| Thesis Health | Active theses, status | Research health |
| Freshness Warnings | Stale data alerts | Data trust |
| Recent Activity | Last 5 updates | Context |
| Sector Allocation | Pie chart | Diversification view |

### What Does NOT Belong

| Section | Why Not |
|---|---|
| P&L chart | Not primary focus |
| Real-time prices | Not a trading app |
| News feed | Not a monitoring tool |
| Market movers | Not aligned with long-term investing |

### Dashboard Layout

```
┌─────────────────────────────────────────────────────┐
│ Portfolio Dashboard                                  │
├──────────────┬──────────────┬───────────────────────┤
│ Positions    │ Conviction   │ Sector Allocation     │
│ 5 active     │ 3 High 🟢    │ Tech: 60%             │
│ 2 closed     │ 2 Medium 🟠  │ Staples: 20%          │
│              │ 0 Low 🟡     │ Energy: 20%           │
├──────────────┴──────────────┴───────────────────────┤
│ Thesis Health                                        │
│ 🟢 3 Active  🟡 1 Reviewing  🔴 0 At Risk           │
├─────────────────────────────────────────────────────┤
│ Recent Activity                                      │
│ • AAPL: Conviction Medium → High (2026-06-20)       │
│ • NVDA: Added note "AI thesis" (2026-06-19)         │
│ • KO: Thesis updated (2026-06-18)                   │
├─────────────────────────────────────────────────────┤
│ Freshness Warnings                                   │
│ 🟡 JPM: Filing data stale (>90 days)                │
│ 🟡 AMZN: Metrics aging (60 days)                    │
└─────────────────────────────────────────────────────┘
```

---

## Learning Loop

### Decision Journal

When closing a position:

```
┌─────────────────────────────────────────────┐
│ Close Position: AAPL                         │
├─────────────────────────────────────────────┤
│ Entry: 2025-06-15 @ $150.00                │
│ Exit: 2026-06-20 @ $298.00                 │
│ Return: +98.7%                              │
├─────────────────────────────────────────────┤
│ Original Thesis                              │
│ "Services revenue compounds. Ecosystem      │
│  durable. Valuation reasonable."            │
├─────────────────────────────────────────────┤
│ Outcome Assessment                           │
│ ☑ Thesis validated                          │
│ ☐ Thesis invalidated                        │
│ ☐ Partially validated                       │
├─────────────────────────────────────────────┤
│ What Was Correct                             │
│ "Services growth thesis played out.         │
│  Ecosystem durability confirmed."           │
├─────────────────────────────────────────────┤
│ What Was Wrong                               │
│ "Underestimated AI impact on multiple       │
│  expansion. PE expanded from 25 to 39."     │
├─────────────────────────────────────────────┤
│ Lessons Learned                              │
│ "Pay more attention to multiple expansion   │
│  risk. Quality companies can get expensive."│
├─────────────────────────────────────────────┤
│ [Save & Close Position]                      │
└─────────────────────────────────────────────┘
```

### Learning Features

| Feature | Purpose |
|---|---|
| Outcome tracking | Did the thesis play out? |
| Correct/Wrong analysis | What assumptions were right/wrong? |
| Lessons learned | What would I do differently? |
| Pattern recognition | What types of decisions do I get right/wrong? |

### Portfolio Review

Periodic review workflow:
```
1. Open Portfolio
2. Review each position
3. Check: Is thesis still valid?
4. Check: Has conviction changed?
5. Update if needed
6. Close positions where thesis invalidated
```

---

## Research Integration

### Portfolio ↔ Research Connections

| Integration | How |
|---|---|
| Notes | Position has linked notes |
| Theses | Position has linked thesis |
| Comparison | Position references comparison decisions |
| Conviction | Position tracks conviction from research |
| Watchlists | Watchlist companies can become positions |

### Research → Portfolio Flow

```
Research → Thesis → Conviction → Position → Monitor → Close → Learn
```

### Portfolio → Research Flow

```
Position → Review Thesis → Update Conviction → Add Note → Close → Record Outcome
```

---

## Future Readiness

### Indonesia Support

Portfolio works for IDX companies:
- BBCA position with Indonesia thesis
- IDR currency
- IDX-specific metrics

### Multiple Portfolios

Future: support multiple portfolios
- Personal Portfolio
- Retirement Portfolio
- Family Portfolio

### Benchmark Tracking

Future: compare portfolio vs benchmark
- Portfolio return vs IHSG
- Sector allocation vs IHSG
- Quality score vs IHSG

### Sector Exposure

Future: analyze portfolio diversification
- Sector allocation chart
- Concentration warnings
- Diversification score

---

## Product Risks

### P&L Obsession

**Risk:** Users focus on returns instead of research quality.

**Mitigation:** Portfolio emphasizes thesis and conviction, not P&L. Returns are available but not primary.

### Feature Creep

**Risk:** Portfolio becomes a full broker integration.

**Mitigation:** Portfolio is a decision tracker, not a trading tool. No broker integration.

### Abandoned Positions

**Risk:** Users open positions but never update or close them.

**Mitigation:** Freshness warnings prompt users to review stale positions.

### Empty Portfolio

**Risk:** New users have no positions. Page feels empty.

**Mitigation:** Provide example portfolio. Link to screener for discovery.

---

## Recommendation

1. **Portfolio is a decision tracker.** Track why you own something, not just what you own.

2. **Thesis is central.** Every position should have a linked thesis.

3. **Conviction evolves.** Track how confidence changes over time.

4. **Learning is the moat.** Closed positions should teach lessons.

5. **Watchlists are pre-portfolio.** Research Queue → Watchlist → Portfolio.

6. **Dashboard is minimal.** Thesis health, freshness warnings, recent activity.

7. **No P&L obsession.** Returns are secondary to research quality.
