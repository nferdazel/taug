# D1.2 — Research Workflow & Decision Architecture Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Research Workflow Audit

### Complete Journey

```
Discover Company → Open Company → Research Company → Write Thesis → Create Position → Review Position → Close Position → Record Outcome → Learn
```

### Current Friction Points

| Step | Friction | Severity |
|---|---|---|
| Discover Company | Screener or company list | Low |
| Open Company | Navigation works | Low |
| Research Company | Notes + thesis CRUD works | Low |
| Write Thesis | Dialog form works | Medium |
| Create Position | Separate workspace | Medium |
| Review Position | No automated alerts | Medium |
| Close Position | Manual workflow | Low |
| Record Outcome | Dialog works | Low |
| Learn | Not visible in workflow | High |

### Missing Workflow Signals

- No "stale thesis" detection
- No "position needs review" automation
- No "learning patterns" visibility
- No cross-company research comparison

---

## Company Workspace Redesign

### Before
- Metrics-first layout
- Research hidden behind tabs
- No decision guidance

### After
- **Decision prompt** — primary object at top
- **Research state** — thesis + notes inline
- **Key metrics** — supporting, below research
- **Company summary** — background context

### Decision Prompt States

| State | Title | Description | Action |
|---|---|---|---|
| No thesis, no notes | Not Yet Researched | "Start by creating research notes" | Create Note |
| Has notes, no thesis | Research in Progress | "N notes created. Consider formalizing into thesis." | Create Thesis |
| Has thesis | Thesis Active | "Thesis 'X' is active. Consider updating or creating position." | Review Thesis |

### Key Design Change

Research is now the primary object. Metrics support the research decision. Not the other way around.

---

## Research Workspace Redesign

### Before
- Tab-driven (Queue / Theses / Notes)
- Empty tabs when no data
- Content library feel

### After
- **Section-driven** (Active Research + Recent Theses + Recent Notes)
- Inline search in header
- Each section has its own empty state
- Research inbox feel

### Key Design Change

Research Workspace is now a work inbox. Users see everything at once. No tab switching required. Focus on what needs attention.

---

## Portfolio Workspace Redesign

No changes in this phase. Portfolio was already redesigned in D1.1.

---

## Research State System

### States

| State | Definition | Trigger |
|---|---|---|
| Not Researched | No notes, no thesis | Default |
| Research In Progress | Has notes, no thesis | Notes created |
| Thesis Active | Has thesis | Thesis created |
| Position Open | Has active position | Position created |
| Review Needed | Thesis or research stale | Manual or automated |
| Closed | Position closed | Position closed |

### Transitions

```
Not Researched → Research In Progress → Thesis Active → Position Open → Closed
                                      → Review Needed → Thesis Active
```

---

## Next Action System

Every company workspace shows a context-aware "Next Action":

| State | Next Action |
|---|---|
| Not Researched | Create Note |
| Research In Progress | Create Thesis |
| Thesis Active | Review Thesis |
| Position Open | Review Position |
| Review Needed | Update Research |

---

## Before vs After

| Aspect | Before | After |
|---|---|---|
| Company Overview | Metrics-first | Decision-first |
| Decision guidance | None | Context-aware prompt |
| Research state | Hidden in tabs | Primary display |
| Research Workspace | Tab-driven content | Section-driven inbox |
| Empty states | Large centered messages | Inline within sections |
| User intent | "What data exists?" | "What should I do next?" |

---

## Remaining Workflow Gaps

| Gap | Priority | When |
|---|---|---|
| Stale thesis detection | Medium | Post-MVP |
| Position review automation | Medium | Post-MVP |
| Learning patterns visibility | Medium | Post-MVP |
| Cross-company comparison | Low | Post-MVP |

---

## Recommendation

1. **Accept.** Workflows now support thinking, not just data viewing.
2. **Next:** Automate stale thesis detection.
3. **Future:** Learning patterns visibility.
