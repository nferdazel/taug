# P0.6 MASTER PLAN — Dead Space Elimination & Decision-Centric UX

**Date:** 2026-06-22
**Status:** CONDITIONAL APPROVAL — 3 blocking findings to resolve

---

## 1. Executive Summary

TAUG's core workflow is visible (Company → Research → Thesis → Position → Lessons → Patterns) but pages feel like databases, not a Research Operating System. The problem is not lack of features — it's lack of guidance, context, and next actions.

**Goal:** Make every page answer:
1. Where am I?
2. What is the current state?
3. What should I do next?

---

## 2. Dead Space Findings

| Page | Severity | Problem |
|---|---|---|
| **Research Tab** | HIGH | All CRUD, no workflow guidance. No progress indicators. No next actions. |
| **Portfolio Workspace** | HIGH | Patterns tab is flat text. Active positions lack P&L. No attention routing. |
| **Company Overview** | MODERATE | Empty state generic. Key Metrics dead when null. No research snapshot. |
| **Research Workspace** | MODERATE | Good prioritization but empty states lack CTAs. |
| **Financials** | LOW-MODERATE | Solid when populated. Empty state is dead text. |
| **Settings** | LOW | Spacer() creates dead vertical space. |

---

## 3. Blocking Findings (Must Resolve Before Implementation)

### F1: State Machine Fragmentation

Three streams define overlapping "What should I do next?" state machines:
- Company Overview: 6-state "Next Action"
- Company Research: 4-step "Research Progress"
- Research Workspace: "Needs Attention" hero

**Fix:** Define ONE canonical `ResearchProgressionState` in `shared/models/`. All surfaces derive from this single source of truth.

### F2: Financials Sidebar Scope

68/32 split risks data density. Sidebar must NOT duplicate per-period headers.

**Fix:** Sidebar shows aggregate context only. Collapsible on viewports < 1200px.

### F3: Settings Schema Gaps

Only 2 settings exist (timezone, density_mode). 5 proposed sections need schema support.

**Fix:** Defer Research/Workspace/Data sections. Implement Profile + Account + existing settings in new layout.

---

## 4. Quick Wins (< 1 day)

| # | Change | File | Impact |
|---|---|---|---|
| 1 | Add CTA buttons to empty states | research_tab.dart | Eliminates dead empty cards |
| 2 | Hide empty metrics grid | overview_tab.dart | Eliminates 6 dead cells |
| 3 | Fix source date in financials | financials_tab.dart | Shows actual date, not DateTime.now() |
| 4 | Remove Spacer() in settings | settings_page.dart | Eliminates dead vertical space |
| 5 | Add "View All" links | research_workspace_page.dart | Connects to filtered views |
| 6 | Conditional section rendering | research_workspace_page.dart | Eliminates empty section dead space |

---

## 5. Medium Wins (1-3 days)

| # | Change | Files | Impact |
|---|---|---|---|
| 1 | Canonical ResearchProgressionState | shared/models/, overview_tab, research_tab, research_workspace | Consistent guidance across all surfaces |
| 2 | Research Progress checklist | research_tab.dart | Users know what "done" looks like |
| 3 | Suggested Next Step | research_tab.dart | Eliminates decision fatigue |
| 4 | Research Snapshot grid | overview_tab.dart | Instant situational awareness |
| 5 | Needs Attention hero | research_workspace_page.dart | Prioritizes what needs doing |
| 6 | Merged timeline | research_workspace_page.dart | Consolidates theses + notes |
| 7 | Collapsible thesis sections | research_tab.dart | Reduces visual noise |

---

## 6. High Impact Changes (3-5 days)

| # | Change | Files | Impact |
|---|---|---|---|
| 1 | Financials two-pane layout | financials_tab.dart | Research context alongside data |
| 2 | Settings full workspace | settings_page.dart, settings_provider.dart | Professional settings experience |
| 3 | Active position P&L | portfolio_workspace_page.dart | Real-time decision context |
| 4 | Patterns visual charts | portfolio_workspace_page.dart | Pattern recognition is visual |

---

## 7. Wireframes (ASCII)

### Company Overview — Next Action + Research Snapshot

```
┌──────────────────────────────────────────────────────────────────┐
│  NEXT ACTION                                        [accent bar] │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  ●  Write Thesis  ──  "You have 3 notes but no thesis.    │  │
│  │     Formalize your research into a stance."       [GO →]  │  │
│  └────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  RESEARCH SNAPSHOT                                               │
│  ┌──────────────┬──────────────┬──────────────┬──────────────┐  │
│  │  THESIS      │  NOTES       │  QUESTIONS   │  POSITION    │  │
│  │  ● Bullish   │  ● 3 items   │  ● 2 open    │  ● None      │  │
│  │    High      │    Latest:    │    1 critical │              │  │
│  │    conviction│    06/20      │              │              │  │
│  └──────────────┴──────────────┴──────────────┴──────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  DATA TRUST (existing)                                           │
│  KEY METRICS (existing)                                          │
│  ABOUT (existing)                                                │
└──────────────────────────────────────────────────────────────────┘
```

### Company Research — Progress + Next Step

```
┌──────────────────────────────────────────────────────────────────┐
│  RESEARCH PROGRESS                                    2/4        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  [✓] Notes created        ── 3 notes, latest 06/20        │  │
│  │  [✓] Thesis written       ── Bullish / High conviction     │  │
│  │  [ ] Questions answered   ── 2 open, 1 critical            │  │
│  │  [ ] Position created     ── No position yet               │  │
│  └────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  SUGGESTED NEXT STEP                                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  ?  Answer 2 open questions before creating a position.    │  │
│  │     1 critical question may affect your thesis.    [GO →]  │  │
│  └────────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────────┤
│  MY THESIS (collapsible sections)                                │
│  QUESTIONS (existing)                                            │
│  NOTES (existing)                                                │
└──────────────────────────────────────────────────────────────────┘
```

### Research Workspace — Needs Attention Hero

```
┌──────────────────────────────────────────────────────────────────┐
│  RESEARCH WORKSPACE                                              │
│  ┌──────────┬──────────┬──────────┬──────────┐                  │
│  │ 5        │ 3        │ 12       │ 2        │                  │
│  │ COMPANIES│ THESES   │ NOTES    │ QUESTIONS│                  │
│  └──────────┴──────────┴──────────┴──────────┘                  │
├──────────────────────────────────────────────────────────────────┤
│  NEEDS ATTENTION                                                 │
│  ⚠ AAPL — No thesis, 4 notes          [Create Thesis →]         │
│  ⚠ TSLA — Thesis expired 45d ago      [Review Thesis →]         │
│  ? "Is margin compression durable?"    CRITICAL · 12d  [Answer →]│
├──────────────────────────────────────────────────────────────────┤
│  ACTIVE RESEARCH (compact rows)                                  │
│  RECENT ACTIVITY (merged timeline)                               │
│  OPEN QUESTIONS (critical/high only)                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. Final Prioritized Roadmap

### Phase 1: Foundation (Quick Wins)
1. Define canonical `ResearchProgressionState` model
2. Add CTA buttons to empty states
3. Hide empty metrics grid
4. Fix source date in financials
5. Remove Spacer() in settings

### Phase 2: Research Tab (Highest Impact)
6. Add Research Progress checklist
7. Add Suggested Next Step
8. Add collapsible thesis sections
9. Extract _ThesisFormDialog widget

### Phase 3: Overview + Workspace
10. Add Next Action state machine
11. Add Research Snapshot grid
12. Add Needs Attention hero
13. Add merged timeline

### Phase 4: Financials + Settings
14. Add Financials two-pane layout (collapsible sidebar)
15. Add Settings full workspace (Profile + Account only)

### Phase 5: Portfolio Polish
16. Add active position P&L
17. Add Patterns visual charts

---

## 9. Rules

- NO decorative charts
- NO fake analytics
- NO dashboard fluff
- NO random KPIs
- YES workflow guidance
- YES progress indicators
- YES research context
- YES actionable next steps
- YES decision support

**TAUG is a Research OS. Not a finance dashboard.**

---

*Evidence > Opinions. Guidance > Decoration. Decision Support > Dashboards.*
