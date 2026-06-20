# Alpha Readiness Review

**Date:** 2026-06-20
**Type:** Product review — no implementation
**Perspective:** Product Designer + Staff Engineer + Power User + Internal Alpha Tester

---

## Executive Summary

TAUG is **functionally usable** for company research but has significant UX friction that would confuse an alpha user. The core workflow (Browse → Open → Read → Write) works end-to-end. The biggest gaps are: (1) no clear onboarding or guidance, (2) research status is invisible, (3) financial tables lack context, (4) the old terminal UI coexists with new workspace UI creating confusion. The platform is ready for a **guided alpha** with a human walking the user through, but not ready for **unguided alpha**.

**Alpha Readiness Score: 5.5 / 10**

---

## Workflow Review

### Discover → Research Flow

```
Open Companies → Search Company → Open Workspace → Read Financials → Create Thesis → Create Notes
```

| Step | Friction | Severity |
|---|---|---|
| Open Companies | Default route is `/companies` ✅ | Low |
| Search Company | Search works, but no visual feedback on filter | Medium |
| Open Workspace | Click navigates correctly ✅ | Low |
| Read Financials | Tables work but lack context (no column headers explanation) | Medium |
| Create Thesis | Dialog works but stance/conviction selectors are small | Medium |
| Create Notes | Dialog works, plain text only ✅ | Low |

**Key friction:** A user who has never seen a financial statement won't understand the financials tab. There's no guidance on what "Gross Profit" means or how it relates to Revenue.

---

## Navigation Review

### Global Navigation

| Aspect | Status | Issue |
|---|---|---|
| Tab bar | ✅ Works | 12 legacy tabs + new workspace tabs coexist |
| Active indicator | ✅ Works | Blue underline on active tab |
| Brand | ✅ Works | "TAUG" logo on left |

**Problem:** The navigation shows both old terminal tabs (Brief, Market, Chart, News, Policy, Calendar) and new workspace tabs (Companies, Research, Portfolio, Data). An alpha user would be confused by 12 tabs when only 5 are relevant.

### Company Navigation

| Aspect | Status | Issue |
|---|---|---|
| Companies → Workspace | ✅ Works | Click row navigates to `/companies/:id` |
| Workspace tabs | ✅ Works | Overview/Financials/Research switch correctly |
| Back navigation | ⚠️ Partial | Browser back button works, but no in-app back |

### Tab Navigation

| Aspect | Status | Issue |
|---|---|---|
| Overview → Financials | ✅ Works | Tab click switches |
| Financials → Research | ✅ Works | Tab click switches |
| Tab state preserved | ✅ Works | Switching tabs preserves scroll |

---

## Research Experience Review

### Notes

| Aspect | Status | Issue |
|---|---|---|
| Create note | ✅ Works | Dialog with title + body |
| Edit note | ✅ Works | Pre-fills existing values |
| Delete note | ✅ Works | Popup menu with delete |
| Notes list | ✅ Works | Shows all notes for company |
| Empty state | ✅ Works | "No notes yet" message |

**Friction:** No way to see all notes across companies. Notes are company-scoped only.

### Thesis

| Aspect | Status | Issue |
|---|---|---|
| Create thesis | ✅ Works | Dialog with stance + conviction + summary + bull/bear |
| Edit thesis | ✅ Works | Pre-fills existing values |
| Delete thesis | ✅ Works | Popup menu |
| Thesis display | ✅ Works | Shows full thesis in research tab |
| Thesis snapshot | ✅ Works | Shows on overview tab |

**Friction:** Only one thesis per company. No thesis history. No way to compare theses across companies.

### Research Status

| Aspect | Status | Issue |
|---|---|---|
| Status badge | ✅ Works | Shows "Not Researched" or "Researching" |
| Auto-detection | ✅ Works | Changes when notes/theses created |
| Conviction badge | ✅ Works | Blue/yellow/gray |

**Friction:** Research status only changes after notes/theses are created via the app. If data was created externally, status won't update.

---

## Financial Experience Review

### Financial Tables

| Aspect | Status | Issue |
|---|---|---|
| Income Statement | ✅ Works | Revenue, COGS, Gross Profit, OpEx, Op Income, Net Income |
| Balance Sheet | ✅ Works | Assets, Liabilities, Equity, Cash, Debt |
| Cash Flow | ✅ Works | Operating CF, CapEx |
| Period columns | ✅ Works | Up to 4 annual periods |
| Value formatting | ✅ Works | T/B/M/K suffixes |

**Friction:**
- No line-item expansion (only key metrics shown)
- No quarterly toggle
- No year-over-year change indicators
- No context on what each line item means
- Missing: Depreciation, R&D, Interest, Tax (not in key metrics list)

### Metric Presentation

| Aspect | Status | Issue |
|---|---|---|
| Key metrics grid | ✅ Works | 6 metrics with badges |
| Value formatting | ✅ Works | Percentage, ratio, monetary |
| Trust indicators | ✅ Works | Quality + freshness badges |

**Friction:** No explanation of what PE=39 means. No comparison to sector average. No historical trend.

---

## Trust Layer Review

### Quality Badge

| Aspect | Status | Issue |
|---|---|---|
| Display | ✅ Works | Green/yellow/red badge |
| Score | ✅ Works | Percentage shown |
| Meaning | ⚠️ Unclear | User doesn't know what "83% quality" means |

### Freshness Badge

| Aspect | Status | Issue |
|---|---|---|
| Display | ✅ Works | Green/yellow/red badge |
| Status | ✅ Works | Fresh/Aging/Stale |
| Meaning | ⚠️ Unclear | User doesn't know what "Fresh" means in days |

### Research Status

| Aspect | Status | Issue |
|---|---|---|
| Display | ✅ Works | Badge with icon |
| Auto-update | ✅ Works | Changes when notes/theses created |

**Overall trust assessment:** Trust indicators are visible but lack context. A user sees "83% Quality" but doesn't know what it measures or why it matters.

---

## Technical Debt Review

### Legacy Company Page

**Issue:** Old terminal-era `company_page.dart` (1702 lines) coexists with new `company_workspace_page.dart`. Both are accessible via different routes.

**Risk:** User confusion. Old page has different UI, different data sources, different behavior.

**Recommendation:** Remove old company page or redirect `/company` to `/companies/:id`.

### Duplicate Routes

**Issue:** `/company` (old) and `/companies/:id` (new) both exist. Old terminal tabs (Brief, Market, Chart, etc.) still accessible.

**Risk:** User lands on old terminal page instead of new workspace.

**Recommendation:** Redirect old routes to new workspace routes.

### AppTable Limitations

**Issue:** Custom `AppTable` uses Flutter's basic `DataTable`. No sorting, no column visibility, no virtualization.

**Risk:** Financial tables with 20+ rows may be slow. No sorting capability.

**Recommendation:** Defer Syncfusion integration until screener is built.

### RLS Assumptions

**Issue:** `research_notes` and `investment_theses` are RLS-locked to authenticated user. Service role can't read them.

**Risk:** Background workers can't process notes/theses for quality scoring or search indexing.

**Recommendation:** Add service_role SELECT grant when research workspace is built.

---

## MVP Gaps

### Missing But Critical

| Gap | Impact | Why Critical |
|---|---|---|
| No onboarding | User doesn't know what to do | First-time experience is confusing |
| No company search from workspace | Can't switch companies without going back | Workflow interruption |
| No keyboard navigation | Desktop users expect keyboard | UX regression from terminal |
| No metric tooltips | User doesn't understand PE, ROE, etc. | Financial literacy barrier |

### Missing But Optional

| Gap | Impact | Why Optional |
|---|---|---|
| No quarterly toggle | Limited financial analysis | Annual data sufficient for MVP |
| No charts | Visual analysis missing | Tables are primary, charts are post-MVP |
| No comparison | Can't compare companies | Post-MVP feature |
| No portfolio tracking | Can't track positions | Post-MVP feature |
| No data workspace | Trust details hidden | Badges sufficient for MVP |

### Future Features

| Feature | When |
|---|---|
| Screener | Post-MVP |
| Comparison | Post-MVP |
| Dashboard | Post-MVP |
| Rich text notes | Post-MVP |
| Indonesia expansion | Post-MVP |
| Mobile adaptation | Future |

---

## Alpha Readiness Score

| Category | Score | Justification |
|---|---|---|
| Navigation | 7/10 | Works but has legacy tabs confusing the experience |
| Research Workflow | 6/10 | Notes + thesis work, but no guidance or onboarding |
| Financial Workflow | 5/10 | Tables work but lack context, no tooltips, no trends |
| Trust Layer | 6/10 | Badges visible but meaning unclear |
| Responsiveness | 7/10 | Desktop works, tablet untested, mobile future |
| Implementation Quality | 7/10 | Clean code, good patterns, some legacy debt |
| **Overall Alpha Readiness** | **5.5/10** | **Functional but not self-explanatory** |

### Justification

**5.5/10** means: A power user who understands financial statements and has someone walking them through the workflow can use TAUG effectively. A new user without guidance would be lost.

**What works:**
- Core workflow is complete (Browse → Open → Read → Write)
- Data is real and accurate
- Trust indicators exist
- CRUD operations work

**What doesn't work:**
- No onboarding or guidance
- Legacy UI coexists with new UI
- Financial tables lack context
- Research status invisible until notes created

---

## Recommended Next Phase

### Option A: Research Workspace
- Cross-company notes, theses, search
- Builds on existing research tab
- **Score: Medium priority**

### Option B: Portfolio
- Position tracking, thesis-linked positions
- Requires research workflow to be solid first
- **Score: Lower priority**

### Option C: UX / Polish Pass
- Remove legacy terminal tabs
- Add onboarding
- Add metric tooltips
- Improve empty states
- **Score: Highest priority for alpha**

### Option D: Technical Debt Cleanup
- Remove old company page
- Consolidate routes
- Fix RLS grants
- **Score: Medium priority**

### Recommendation: **Option C — UX / Polish Pass**

**Rationale:** The platform is functionally complete for company research. The biggest barrier to alpha adoption is UX friction, not missing features. A polish pass would:

1. Remove legacy terminal tabs (reduce confusion)
2. Add metric tooltips (reduce financial literacy barrier)
3. Improve empty states (guide new users)
4. Add keyboard navigation (desktop UX)
5. Clean up old routes (reduce confusion)

This makes the existing features usable before adding new ones.
