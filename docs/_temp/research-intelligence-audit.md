# TAUG Research Intelligence Audit

**Date:** 2026-06-22
**Purpose:** What makes TAUG a Research Operating System?

---

## Verdict: PARTIALLY — Design Complete, Implementation Pending

---

## What Differentiates TAUG?

### From Note Taking App

| Feature | Note Taking App | TAUG |
|---|---|---|
| Notes | Free text | Linked to thesis fields |
| Theses | Not supported | Structured (10 fields) |
| Decisions | Not tracked | Position with thesis linkage |
| Outcomes | Not recorded | Outcome + lessons |
| Learning | Not possible | Lessons aggregation |
| Freshness | Not tracked | Research freshness indicators |

**TAUG Advantage:** Structured research workflow with decision tracking and learning.

---

### From Stock Screener

| Feature | Stock Screener | TAUG |
|---|---|---|
| Discovery | Metric-based filtering | Research-based discovery |
| Analysis | Numbers only | Numbers + thesis + notes |
| Decisions | Not tracked | Position with conviction |
| Learning | Not possible | Lessons from outcomes |
| Questions | Not tracked | Research questions |

**TAUG Advantage:** Research-first, not metrics-first. Decisions tracked with context.

---

### From Portfolio Tracker

| Feature | Portfolio Tracker | TAUG |
|---|---|---|
| Positions | Prices + P&L | Decisions + thesis + lessons |
| Tracking | Performance | Conviction + review |
| Learning | Not possible | Outcome recording |
| Research | Not supported | Full research workflow |
| Intelligence | Not possible | Invalidation conditions |

**TAUG Advantage:** Tracks decisions, not prices. Learning from outcomes.

---

## Research Questions

**Current State:** Not implemented.

**Design:**
- `research_questions` table
- Open questions tracked per company
- Questions link to theses when answered
- "OPEN QUESTIONS" section in Research Workspace

**Evidence:** Design document complete. No implementation.

---

## Hypothesis Tracking

**Current State:** Partially implemented.

**Evidence:**
- Thesis captures stance (bullish/neutral/bearish)
- Thesis captures conviction (low/medium/high)
- Thesis captures bull/bear case
- Thesis captures assumptions, catalysts, risks, exit conditions

**Gap:** No structured invalidation triggers. No assumption monitoring.

---

## Evidence Tracking

**Current State:** Not implemented.

**Design:**
- `note_thesis_links` junction table
- Notes linked to thesis fields (bull_case, bear_case, assumptions, etc.)
- Relationship types (supports, contradicts, updates, context)
- Evidence section in thesis card

**Evidence:** Design document complete. No implementation.

---

## Review Cadence

**Current State:** Not implemented.

**Design:**
- `last_reviewed_at` column on `investment_theses`
- `researchFreshness` getter (fresh/aging/stale/expired)
- "NEEDS REVIEW" section in Research Workspace
- "Mark Reviewed" action resets freshness

**Evidence:** Design document complete. No implementation.

---

## Invalidation Logic

**Current State:** Not implemented.

**Design:**
- `invalidation_conditions` table
- Structured triggers (metric code, operator, threshold)
- `thesis_assumptions` table
- `assumption_check_v` view for breach detection
- Breach indicators on thesis card

**Evidence:** Design document complete. No implementation.

---

## Learning Loop

**Current State:** Not implemented.

**Design:**
- Surface company lessons in thesis dialog
- Prioritized cascade (company > stance > all)
- Micro-summaries (not dashboards)
- "Apply to New Research" on lesson cards (implemented)

**Evidence:** Design document complete. Implementation pending.

---

## Research Intelligence Score

| Feature | Score | Evidence |
|---|---|---|
| Research Questions | 0/10 | Not implemented |
| Hypothesis Tracking | 6/10 | Thesis fields exist, no monitoring |
| Evidence Tracking | 0/10 | Not implemented |
| Review Cadence | 0/10 | Not implemented |
| Invalidation Logic | 0/10 | Not implemented |
| Learning Loop | 2/10 | Lessons captured, not surfaced |
| **Overall** | **1.3/10** | **Design complete, implementation pending** |

---

## What Would Make TAUG a Research Operating System?

1. **Research Questions** — Track open investigation threads
2. **Evidence Tracking** — Connect notes to thesis fields
3. **Invalidation Conditions** — Structured exit triggers with monitoring
4. **Thesis Lifecycle** — Status field + freshness + review workflow
5. **Learning Loop** — Surface lessons during thesis creation

**Status:** All 5 designed. None implemented.

---

*This audit is maintained by God-3 Agent.*
