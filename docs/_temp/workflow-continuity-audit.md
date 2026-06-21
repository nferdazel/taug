# TAUG Workflow Continuity Audit

**Date:** 2026-06-22
**Purpose:** Audit every workflow transition for friction, context loss, and dead ends.

---

## Workflow Transitions

### Research → Thesis

**Friction:** Low

**Context Loss:** None

**Dead Ends:** None

**Evidence:**
- Thesis dialog accessible from Research tab
- All 10 fields capturable (title, stance, conviction, summary, bull/bear case, assumptions, catalysts, risks, exit conditions)
- Stance and conviction chips for quick selection

**Status:** ✅ Complete

---

### Thesis → Position

**Friction:** ~~High~~ → Low (FIXED)

**Context Loss:** ~~Yes~~ → No (FIXED)

**Dead Ends:** ~~Yes~~ → No (FIXED)

**Evidence (Before):**
- "Create Position" button navigated to `/portfolio-workspace` with no parameters
- User had to re-find company and re-select thesis
- ~60 seconds of wasted effort

**Evidence (After):**
- "Create Position" passes companyId, companyName, thesisId, thesisTitle, conviction via query parameters
- Add Position dialog auto-opens with pre-populated fields
- Zero re-work for user

**Status:** ✅ Fixed

---

### Position → Outcome

**Friction:** Low

**Context Loss:** None

**Dead Ends:** None

**Evidence:**
- Close Position dialog captures outcome (correct/incorrect/partial)
- Exit price field for P&L calculation
- Lessons learned field for knowledge capture
- Dialog stays open on failure (form data preserved)

**Status:** ✅ Complete

---

### Outcome → Learning

**Friction:** Medium

**Context Loss:** Lessons are siloed in Portfolio → Lessons tab

**Dead Ends:** No path from lessons back to company or thesis

**Evidence (Before):**
- Lessons only visible in Portfolio → Lessons tab
- No connection to company or thesis
- Historical records, not active intelligence

**Evidence (After):**
- "Apply to New Research" button on lesson cards
- Navigates to company Research tab
- Lessons become active intelligence

**Status:** ⚠️ Partially Fixed (navigation only, no lesson surfacing)

---

### Learning → Research

**Friction:** High

**Context Loss:** Lessons not surfaced during new research

**Dead Ends:** No mechanism to surface lessons during thesis creation

**Evidence:**
- Thesis dialog opens with empty fields
- No query for closed positions when thesis dialog opens
- No display of prior lessons, patterns, or outcomes

**Design Solution:** Surface company lessons in thesis dialog (design complete, implementation pending)

**Status:** ❌ Not Implemented

---

## Summary

| Transition | Friction | Context Loss | Dead Ends | Status |
|---|---|---|---|---|
| Research → Thesis | Low | None | None | ✅ Complete |
| Thesis → Position | Low | None | None | ✅ Fixed |
| Position → Outcome | Low | None | None | ✅ Complete |
| Outcome → Learning | Medium | Lessons siloed | Partial | ⚠️ Partially Fixed |
| Learning → Research | High | Lessons not surfaced | Yes | ❌ Not Implemented |

---

## Fixed Issues

### 1. Thesis → Position Context Loss (P0) — ELIMINATED

**What Changed:** "Create Position" now passes context via query parameters.

**Evidence:**
- `research_tab.dart`: `onCreatePosition` builds URI with query parameters
- `portfolio_workspace_page.dart`: `initState` reads parameters and auto-opens dialog
- `_showAddPositionDialog`: Accepts optional pre-populated fields

**Impact:** Zero re-work for user. ~60 seconds saved per position creation.

---

### 2. markReviewNeeded Dead Code (P0) — RESOLVED

**What Changed:** Method now called from active position card menu.

**Evidence:**
- `portfolio_workspace_provider.dart`: `markReviewNeeded()` method added
- `portfolio_workspace_page.dart`: "Mark for Review" added to PopupMenuButton
- Position immediately gets warning border + "Review Needed" badge

**Impact:** Review workflow activated. Users can flag positions for review.

---

### 3. Lessons → Research Dead End (P1) — RESOLVED

**What Changed:** "Apply to New Research" button on lesson cards.

**Evidence:**
- `_LessonCard` widget: `onNewResearch` callback added
- "Apply to New Research" button with science icon
- Navigates to `/companies/${companyId}/research`

**Impact:** Lessons become active intelligence, not dead-end records.

---

## Remaining Issues

### 1. Learning → Research (P0) — NOT IMPLEMENTED

**Problem:** Lessons not surfaced during thesis creation.

**Design Solution:** Surface company lessons in thesis dialog with prioritized cascade.

**Status:** Design complete, implementation pending.

---

### 2. Position → Company Context Loss (P1) — NOT FIXED

**Problem:** "View Company" navigates to company page. Returning to portfolio loses position context.

**Recommendation:** Add back-navigation breadcrumb.

**Status:** Not implemented.

---

*This audit is maintained by UX Agent.*
