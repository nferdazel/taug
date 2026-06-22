# TAUG — Product Philosophy

## Philosophy

TAUG exists to help investors **think better**, not to show them more data.

Every design decision should answer: "Does this help the user make a better investment decision?"

---

## Research First

TAUG's core value proposition is **structured research**.

Users don't just consume data — they:
- Form hypotheses about companies
- Write investment theses
- Track conviction over time
- Record decisions
- Learn from outcomes

The product serves the **thinking process**, not the information need.

---

## Decision Support

TAUG is a **decision support tool**, not a data display tool.

Every screen should help the user answer:
- "What should I do?"
- "What do I think?"
- "What have I learned?"

NOT:
- "What data exists?"
- "What's the latest number?"
- "What's trending?"

---

## Portfolio As Decision Tracking

Portfolio Workspace tracks **decisions**, not prices.

A position record includes:
- Why the user invested (thesis)
- How confident they are (conviction)
- When they decided (entry date)
- What happened (outcome)
- What they learned (lessons)

It does NOT include:
- Real-time P&L
- Broker integration
- Performance charts
- Allocation analytics

---

## Learning System

TAUG's long-term moat is **learning from decisions**.

When a user closes a position, they record:
- Was the thesis correct?
- What assumptions were right?
- What assumptions were wrong?
- What would they do differently?

Over time, users can see:
- Which types of decisions work
- Which assumptions are usually wrong
- Where they consistently make mistakes

This requires NO AI — just structured recording and review.

---

## Why Metrics Are Secondary

Financial metrics (PE, ROE, margins) support research decisions. They are NOT the product.

A user who understands a business and has a clear thesis is more valuable than a user who knows every metric.

TAUG shows metrics to **support** research, not to **be** research.

---

## Why Workflow Matters

The workflow is the product:

```
Discover → Research → Thesis → Decision → Portfolio → Outcome → Learning
```

Every feature must fit into this workflow. Features that don't serve this workflow are deferred.

---

## Historical Product Pivots

### Pivot 1: Terminal → Research Workspace

**When:** Early development

**What happened:** TAUG started as a Bloomberg-style terminal with real-time quotes, charts, order books, and market monitoring.

**Why it changed:** The terminal model serves traders, not researchers. Long-term investors don't need real-time data — they need structured thinking tools.

**What was preserved:** Auth, routing shell, compact UI system, watchlists, portfolio basics.

**What was removed:** Real-time quotes, order books, running trades, market movers, news feed prominence.

### Pivot 2: Data Viewer → Research Operating System

**When:** Mid-development

**What happened:** After building the data pipeline, TAUG felt like a data viewer — tables of numbers with no workflow.

**Why it changed:** Data without workflow is just information consumption. TAUG needed to support the thinking process, not just display data.

**What changed:** Added thesis tracking, conviction system, decision journal, learning loop. Redesigned workspaces around user jobs, not data tables.

---

## Design Principles Summary

1. **Research over data** — Support thinking, not consumption
2. **Decisions over prices** — Track decisions, not P&L
3. **Learning over analytics** — Learn from outcomes, not optimize allocation
4. **Workflow over features** — Every feature serves the research lifecycle
5. **Density over whitespace** — Information density, not breathing room
6. **Clarity over aesthetics** — Professional, not pretty
