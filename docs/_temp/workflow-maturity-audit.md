# TAUG Workflow Maturity Audit

**Created:** 2026-06-22
**Purpose:** Assess workflow maturity and identify dead ends.

---

## Executive Summary

TAUG's workflow is implemented but has context loss at transitions and dead ends that break the research lifecycle.

**Maturity: 4/10 — Structured Data Capture, Not Yet a Learning System**

---

## Workflow Continuity Assessment

### Thesis → Position Context Loss (P0)

**Problem:** "Create Position" button navigates to `/portfolio-workspace` with no parameters. User must re-find company and re-select thesis.

**Impact:** Highest friction point in the workflow. ~60 seconds of wasted effort.

**Recommendation:** Pre-populate Add Position dialog with company and thesis context.

---

### Position → Company Context Loss (P1)

**Problem:** "View Company" navigates to company page. Returning to portfolio loses position context.

**Impact:** No breadcrumb navigation. User must mentally track position.

**Recommendation:** Add back-navigation breadcrumb.

---

### Research → Portfolio Dead End (P1)

**Problem:** Research page shows theses but has no "Create Position" action.

**Impact:** Users must navigate to Portfolio separately.

**Recommendation:** Add "Create Position" action to thesis cards in Research page.

---

### Lessons → Research Dead End (P1)

**Problem:** Lessons tab shows lessons but no path back to company or thesis.

**Impact:** Lessons are historical records, not active intelligence.

**Recommendation:** Add "Apply to New Research" action on lesson cards.

---

## Dead Ends Identified

| Dead End | Location | Impact |
|---|---|---|
| "Create Position" loses context | research_tab.dart:49 | High friction |
| `markReviewNeeded()` never called | portfolio_workspace_repository.dart:123 | Review workflow half-implemented |
| `researchStatus: 'watchlist'` defined but not actionable | research_status_badge.dart:9 | Status exists but no workflow step |
| `researchStatus: 'portfolio'` not auto-set | research_status_badge.dart:10 | Creating position doesn't update status |
| Legacy route redirects collapse features | app_router.dart:35-47 | User confusion |

---

## Positive Patterns

| Pattern | Status |
|---|---|
| Consistent card structure | ✅ |
| Consistent action patterns (PopupMenuButton) | ✅ |
| Consistent data flow (Signal pattern) | ✅ |
| Decision prompts guide workflow | ✅ |
| Empty states with guidance | ✅ |

---

## Top 3 Recommendations

1. **P0: Pre-populate position dialog from thesis context** — Eliminates most painful workflow break
2. **P0: Surface lessons during thesis creation** — Closes learning loop
3. **P0: Wire `markReviewNeeded` to position lifecycle** — Activates review workflow

---

*This audit is maintained by UX Agent.*
