# B5 — Research Workspace Architecture

**Date:** 2026-06-20
**Type:** Product design — no implementation
**Perspective:** Investor + Research Analyst + Knowledge Worker + Product Designer

---

## Executive Summary

TAUG's Research Workspace is where investors build conviction. It's not a note-taking feature — it's a structured thinking environment where research becomes investment decisions. The architecture supports three core activities: **capture** (notes, ideas), **evaluate** (theses, conviction), and **retain** (history, learning).

**Core insight:** The best investors learn from their own decisions. TAUG's Research Workspace should make that learning possible.

---

## Research Philosophy

### What Research Means in TAUG

Research is not information consumption. Research is:
- Understanding a business deeply
- Building a mental model of how it creates value
- Evaluating whether the market correctly prices that value
- Recording assumptions so they can be tested later
- Learning from both correct and incorrect decisions

### Design Principles

1. **Research is thinking, not typing.** The workspace should support structured thinking, not just free-form notes.
2. **Every thesis has a reason.** Users should articulate why, not just what.
3. **Conviction evolves.** The system should track how thinking changes over time.
4. **Decisions are learnable.** Users should be able to review past decisions and learn from them.
5. **Research compounds.** Notes, theses, and watchlists should build on each other over time.

---

## Research Model

### Entity Relationships

```
Research Workspace
├── Notes (atomic research units)
│   ├── Company Notes
│   ├── General Notes
│   └── Macro Notes
├── Theses (structured investment arguments)
│   ├── Bullish Thesis
│   ├── Bearish Thesis
│   └── Neutral Thesis
├── Watchlists (named company collections)
│   ├── Research Queue
│   ├── High Conviction
│   └── Custom Watchlists
├── Collections (tag-based groupings)
│   ├── AI Companies
│   ├── Dividend Growth
│   └── Custom Collections
└── Tags (cross-cutting labels)
    ├── Sector tags
    ├── Theme tags
    └── Custom tags
```

### Ownership Model

| Entity | Owner | Scope |
|---|---|---|
| Notes | User | Per-company or general |
| Theses | User | Per-company |
| Watchlists | User | Named collections |
| Collections | User | Tag-based groups |
| Tags | User | Cross-cutting |

### Lifecycle

| Entity | Create | Update | Archive | Delete |
|---|---|---|---|---|
| Notes | ✅ | ✅ | ✅ | ✅ |
| Theses | ✅ | ✅ | ✅ | ✅ |
| Watchlists | ✅ | ✅ | ✅ | ✅ |
| Collections | ✅ | ✅ | ✅ | ✅ |

---

## Research Workflow

### Primary Workflow: Company Research

```
1. Discover Company
   └── Via Screener, Watchlist, or Search

2. Read Company Workspace
   └── Overview, Financials, Valuation

3. Create Research Note
   └── "Interesting business. High ROE, strong brand."

4. Develop Thesis
   └── Bullish: "Undervalued due to temporary headwinds"

5. Set Conviction
   └── Low → building position

6. Add to Watchlist
   └── "Research Queue"

7. Update Over Time
   └── New note: "Q1 earnings beat expectations"
   └── Update thesis: conviction Low → Medium

8. Make Decision
   └── Buy → add to Portfolio
   └── Pass → record why

9. Revisit
   └── Review thesis quarterly
   └── Update conviction
   └── Learn from outcome
```

### Secondary Workflow: Idea Discovery

```
1. Open Screener
   └── Apply filters: PE < 20, ROE > 15%

2. Browse Results
   └── Click company → Company Workspace

3. Quick Assessment
   └── "Interesting. Need more research."

4. Create Note
   └── "Screener hit. Low PE, high ROE. Investigate."

5. Add to Research Queue
   └── Watchlist: "Research Queue"

6. Deep Research Later
   └── Full company research workflow
```

### Tertiary Workflow: Thesis Review

```
1. Open Research Page
   └── View active theses

2. Select Thesis
   └── "Apple — Bullish since 2025"

3. Review Evidence
   └── Notes, metrics, freshness

4. Update Conviction
   └── Medium → High (thesis playing out)

5. Or Close Thesis
   └── "Thesis invalidated. Sold position."
```

---

## Investment Thesis System

### Thesis Structure

```
Thesis: Apple Inc. — Bullish
├── Summary
│   └── "Apple's ecosystem creates durable competitive advantage 
│        with high switching costs. Services revenue growing 15%+ 
│        annually. Current PE of 39x reasonable for quality."
├── Bull Case
│   ├── Services revenue compounds at 15%+
│   ├── iPhone installed base drives recurring revenue
│   ├── AI integration creates new product category
│   └── Buybacks reduce share count 3-4% annually
├── Bear Case
│   ├── China regulatory risk
│   ├── Smartphone market saturation
│   ├── Premium valuation leaves little margin of safety
│   └── Services growth may decelerate
├── Key Assumptions
│   ├── Services revenue grows 15%+ for 3 years
│   ├── iPhone unit sales remain stable
│   ├── Gross margin stays above 45%
│   └── No major regulatory disruption
├── Catalysts
│   ├── AI product launch (2025)
│   ├── Services revenue inflection
│   └── India market expansion
├── Risks
│   ├── China regulation
│   ├── Competition from Android
│   └── Consumer spending slowdown
├── Valuation View
│   └── "Fair value ~$200. Current price $298. 
│        Paying for quality but limited upside."
├── Disconfirming Evidence
│   └── "If Services growth drops below 10%, thesis is weakened."
├── Exit Conditions
│   ├── "Sell if Services growth < 10% for 2 consecutive quarters"
│   ├── "Sell if PE exceeds 50x without earnings growth"
│   └── "Sell if major China regulatory action"
├── Status: Active
├── Conviction: Medium
├── Created: 2025-06-15
├── Updated: 2026-06-20
└── Linked Notes: 5
```

### Thesis Types

| Type | Meaning | Structure |
|---|---|---|
| Bullish | "I want to buy" | Bull case + catalysts + valuation |
| Bearish | "I want to avoid/short" | Bear case + risks + overvaluation |
| Neutral | "I'm watching" | Mixed signals + trigger conditions |

### Thesis Lifecycle

```
Draft → Active → Updated → Closed (Bought/Passed/Invalidated)
```

---

## Conviction Tracking

### Conviction Levels

| Level | Meaning | Indicator |
|---|---|---|
| Low | "Interesting, need more research" | 🟡 |
| Medium | "Building position, thesis forming" | 🟠 |
| High | "Strong conviction, thesis validated" | 🟢 |
| Closed | "Decision made, thesis complete" | ⚫ |

### Conviction Evolution

```
Low → Medium: Thesis strengthened by new evidence
Medium → High: Thesis validated by earnings/price action
High → Medium: Thesis weakened by new data
Medium → Low: Thesis invalidated
Any → Closed: Decision made (buy/pass/sell)
```

### Revision Tracking

Every conviction change should record:
- **Date** of change
- **Reason** for change
- **Evidence** that triggered change

Example:
```
2026-06-20: Low → Medium
Reason: "Q1 earnings beat. Services revenue +18% YoY."
Evidence: "AAPL Q1 2026 10-Q filing"
```

### Learning from Decisions

When a thesis is closed, record:
- **Outcome:** Did the thesis play out?
- **What was correct:** Which assumptions were right?
- **What was wrong:** Which assumptions were wrong?
- **What to learn:** What would I do differently?

---

## Note Architecture

### Note Types

| Type | Scope | Purpose |
|---|---|---|
| Company Note | Per-company | Research on specific company |
| General Note | Cross-company | Ideas, observations, patterns |
| Macro Note | Economy/market | Macro context, policy analysis |

### Note Structure

```
Note: Apple Q1 2026 Earnings
├── Company: Apple Inc. (AAPL)
├── Type: Company Note
├── Tags: [earnings, services, iphone]
├── Content: "Services revenue $20.8B, +18% YoY. 
│            iPhone revenue $69.7B, +2% YoY.
│            Gross margin 46.9%. Strong quarter."
├── Created: 2026-01-30
├── Updated: 2026-01-30
└── Linked Thesis: Apple — Bullish
```

### Tagging Strategy

| Tag Type | Examples | Purpose |
|---|---|---|
| Topic | earnings, valuation, management | Content classification |
| Theme | AI, cloud, EV, healthcare | Investment theme |
| Quality | thesis-supporting, disconfirming | Research quality |
| Status | initial, updated, verified | Research status |

### Searchability

- Full-text search across all notes
- Filter by company, type, tags, date
- Sort by relevance, date, company

---

## Watchlists

### Default Watchlists

| Name | Purpose | Contents |
|---|---|---|
| Research Queue | "Companies to research" | Screener hits, ideas |
| High Conviction | "Strongest theses" | Companies with High conviction |
| All Companies | "Everything tracked" | All 32+ companies |

### Custom Watchlists

Users create named watchlists:
- "AI Companies"
- "Dividend Aristocrats"
- "Turnaround Stories"
- "ASEAN Exposure"

### Watchlist Properties

- **Name** — user-defined
- **Description** — optional
- **Companies** — list of companies
- **Sort** — by any metric
- **Freshness** — shows data freshness per company

---

## Collections

### What Collections Are

Collections are tag-based groupings that cut across watchlists.

Example:
- Tag "AI" → Collection "AI Companies" (includes NVDA, GOOGL, MSFT, META)
- Tag "Dividend" → Collection "Dividend Growth" (includes KO, PG, JNJ)

### Relationship to Watchlists

| Concept | Watchlist | Collection |
|---|---|---|
| Basis | Manual selection | Tag-based |
| Membership | Explicit | Automatic |
| Purpose | Curation | Discovery |
| Example | "My Watchlist" | "AI Companies" |

### Collection Use Cases

- **Theme tracking:** "Which companies are exposed to AI?"
- **Sector analysis:** "How are my healthcare companies performing?"
- **Quality screening:** "Which companies have ROE > 20%?"

---

## Research Homepage

### Purpose

The Research page is the user's research dashboard. It answers: "What's happening in my research?"

### Layout

```
┌─────────────────────────────────────────────────────┐
│ Research                                             │
├──────────────┬──────────────┬───────────────────────┤
│ My Notes     │ My Theses    │ My Watchlists         │
│              │              │                       │
│ Recent Notes │ Active: 5    │ Research Queue (3)    │
│ 1. AAPL Q1.. │ 1. AAPL 🟢   │ High Conviction (2)   │
│ 2. NVDA AI.. │ 2. NVDA 🟢   │ AI Companies (5)      │
│ 3. KO Div..  │ 3. KO  🟠    │ Dividend Growth (4)   │
│              │ Closed: 2    │                       │
│ [View All]   │ [View All]   │ [Create New]          │
├──────────────┴──────────────┴───────────────────────┤
│ Quick Actions                                        │
│ [New Note] [New Thesis] [Search] [Browse Tags]       │
└─────────────────────────────────────────────────────┘
```

### Primary Actions

1. **Create Note** — quick capture
2. **Create Thesis** — structured thinking
3. **Search** — find anything
4. **Browse** — explore by company, tag, date

### Success Criteria

- User can create a note in 5 seconds
- User can find any note in 10 seconds
- User can review active theses in 30 seconds

---

## Search & Discovery

### Search Scope

| Entity | Searchable Fields |
|---|---|
| Notes | Title, content, tags, company |
| Theses | Summary, bull case, bear case, assumptions |
| Companies | Name, ticker, sector |
| Watchlists | Name, description |
| Tags | Tag name |

### Search UX

```
┌─────────────────────────────────────────────┐
│ 🔍 Search notes, theses, companies...       │
├─────────────────────────────────────────────┤
│ Recent:                                     │
│   📝 Apple Q1 Earnings (2026-01-30)         │
│   📊 Apple — Bullish Thesis                 │
│   🏢 Apple Inc. (AAPL)                      │
├─────────────────────────────────────────────┤
│ Filter: [Notes] [Theses] [Companies] [Tags] │
└─────────────────────────────────────────────┘
```

### Discovery Features

- **Recent activity** — last 10 viewed items
- **Tag cloud** — visual tag exploration
- **Company-centric** — all research grouped by company
- **Timeline** — chronological research view

---

## Knowledge Retention

### The Problem

Investors make decisions, forget why, and repeat mistakes.

### TAUG's Solution

1. **Thesis records** — every decision has a written thesis
2. **Conviction history** — every change is tracked with reason
3. **Assumption testing** — key assumptions are explicit and verifiable
4. **Outcome recording** — when thesis closes, record what happened
5. **Learning capture** — what would I do differently?

### Decision Journal

When closing a thesis:

```
Decision: Buy AAPL at $150 (2025-06-15)
Thesis: Services revenue compounds, ecosystem durable
Outcome: +98% (current $298)
Correct: Services growth thesis played out
Wrong: Underestimated AI impact on multiple expansion
Learning: Pay more attention to multiple expansion risk
```

### Pattern Recognition

Over time, users can review:
- "Which sectors do I get right?"
- "What assumptions do I usually get wrong?"
- "When do I sell too early vs too late?"

---

## Future Readiness

### Portfolio Integration

The research workspace supports future portfolio integration:
- Notes can reference holdings
- Theses can track actual positions
- Conviction can trigger buy/sell signals

### Indonesia Support

The research model is country-agnostic:
- Notes work for any company
- Theses work for any market
- Watchlists can include IDX companies

### Macro Research

Future macro research support:
- Macro notes (FRED, BPS data)
- Economy-level theses
- Macro-company linkages

### Company Comparison

Future comparison features:
- Side-by-side financials
- Thesis comparison
- Conviction comparison

### Collaboration

Future multi-user support:
- Shared watchlists
- Shared notes
- Team theses

---

## Product Risks

### Research Fragmentation

**Risk:** Notes scattered across companies. No unified view.

**Mitigation:** Research Page aggregates all notes, theses, watchlists. Search works across everything.

### Feature Creep

**Risk:** Research workspace becomes too complex.

**Mitigation:** Start with notes + theses + watchlists. Collections and tags are future.

### Empty State

**Risk:** New users have no research. Page feels empty.

**Mitigation:** Provide templates, examples, and screener integration to populate research.

### Abandonment

**Risk:** Users create notes but never revisit.

**Mitigation:** Freshness indicators on theses. "Last updated 30 days ago" prompts.

---

## Recommendation

1. **Start with Notes + Theses.** These are the core research activities.

2. **Watchlists are secondary.** They organize research but don't create it.

3. **Collections are future.** Tags and collections add complexity without core value.

4. **Search is critical.** Users must find their own research easily.

5. **Decision journal is the moat.** Learning from past decisions is TAUG's unique value.

6. **Keep it simple.** Research workspace should feel like a clean notebook, not a project management tool.
