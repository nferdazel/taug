# TAUG Learning Loop Audit

**Date:** 2026-06-22
**Purpose:** Can knowledge compound in TAUG?

---

## Verdict: NOT YET — Design Complete, Implementation Pending

---

## Can Knowledge Compound?

**Current State:** No.

Lessons are captured during position closure but never surfaced during new research. Knowledge dies after creation.

**Evidence:**
- `PortfolioPosition.lessonsLearned` is free text, stored on close
- Lessons aggregation view groups by outcome (correct/incorrect/partial)
- Lessons are ONLY visible in Portfolio → Lessons tab
- When creating a new thesis, users CANNOT access prior lessons
- When creating a new thesis for a company with closed positions, lessons are invisible

---

## Can Lessons Influence Future Research?

**Current State:** No.

The thesis dialog opens with empty fields. No prior context is shown.

**Evidence:**
- `research_tab.dart:200-499` — thesis dialog opens with no lesson context
- No query for closed positions when thesis dialog opens
- No display of prior lessons, patterns, or outcomes

**Design Solution:** Surface company lessons in thesis dialog with prioritized cascade:
1. Same company + same stance → "Your prior bullish NVDA thesis was correct"
2. Same company, any stance → "You've had 2 prior NVDA positions"
3. Same stance, different company → "Your bullish theses are correct 65% of the time"
4. All lessons → "12 total lessons in your knowledge base"

**Status:** Design complete, implementation pending.

---

## Can Users Learn from Prior Mistakes?

**Current State:** Partially.

Users can view lessons in Portfolio → Lessons tab, but must manually recall them when making new decisions.

**Evidence:**
- Lessons tab groups by outcome (correct/incorrect/partial)
- Summary chips show counts
- Lesson cards show company name, return %, outcome, lesson text
- "Apply to New Research" button navigates to company Research tab

**Gap:** Lessons are not automatically surfaced when creating new theses.

---

## Can Users Discover Prior Patterns?

**Current State:** No.

No pattern recognition exists. Users cannot answer:
- "What's my most common mistake?"
- "Are my high-conviction theses usually correct?"
- "Do I tend to sell too early?"

**Evidence:**
- No lesson tagging or categorization
- No conviction calibration
- No stance accuracy tracking
- No time-based learning trends

**Design Solution (Deferred):**
- Lesson categories (timing, valuation, catalyst, risk)
- Conviction accuracy ("Your high-conviction theses: 70% correct")
- Stance patterns ("Your bullish theses tend to be premature")
- Timing analysis ("Average holding period for correct: 45 days")

---

## Learning Loop Status

| Stage | Status | Evidence |
|---|---|---|
| Lesson Capture | ✅ Complete | lessonsLearned field on PortfolioPosition |
| Lesson Storage | ✅ Complete | Stored in portfolio_positions table |
| Lesson Viewing | ✅ Complete | Lessons tab in Portfolio |
| Lesson Surfacing | ❌ Not Implemented | Lessons not shown during thesis creation |
| Pattern Recognition | ❌ Not Implemented | No aggregation or analysis |
| Learning Application | ⚠️ Partial | "Apply to New Research" button (navigation only) |

---

## Minimum Viable Learning Loop

**What:** Surface company lessons in thesis dialog.

**How:**
1. When thesis dialog opens → query closed positions for that company
2. Display lessons in collapsible section at top
3. Show outcome badges, stance, conviction, lesson text

**Effort:** ~100 lines across 3 files:
- `PortfolioRepository.getLessonsForCompany()`
- `WorkspaceProvider.companyLessons` signal
- `ResearchTab._LessonsSection` widget

**Status:** Design complete, implementation pending.

---

## Evidence

**From product-maturity-audit.md:**
> "Lessons are siloed in Portfolio → Lessons tab. When creating a new thesis, users cannot access prior lessons."

**From workflow-maturity-audit.md:**
> "Lessons tab shows lessons but no path back to company or thesis. Lessons are historical records, not active intelligence."

**From research-os-evaluation.md:**
> "When a user closes a position with lessons, those lessons are stored but never surfaced when creating new theses. The user must mentally recall past learnings."

---

*This audit is maintained by UX Agent.*
