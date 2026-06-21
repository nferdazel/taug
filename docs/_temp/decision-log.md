# TAUG Decision Log

**Date:** 2026-06-22
**Purpose:** Record every meaningful decision with context, options, and reasoning.

---

## Decision 1: Surface Lessons in Thesis Dialog

**Context:** Lessons are siloed in Portfolio → Lessons tab. When creating a new thesis, users cannot access prior lessons. The learning loop is broken.

**Alternatives:**
1. Inline collapsible section at top of thesis dialog
2. Sidebar panel next to thesis dialog
3. Notification/toast when thesis dialog opens
4. Separate "Lessons" page (already exists)

**Arguments For (Option 1):**
- Context where decisions are made
- One glance away from thesis creation
- Keeps dialog clean (collapsible)
- No layout changes required

**Arguments Against (Option 1):**
- Adds height to dialog
- May distract from thesis creation

**Final Choice:** Option 1 (Inline collapsible section)

**Consequences:**
- New repository method: `getLessonsForCompany()`
- New signal in WorkspaceProvider: `companyLessons`
- New widget: `_LessonsSection` in thesis dialog
- ~100 lines of code across 3 files

---

## Decision 2: Pre-populate Position Dialog from Thesis

**Context:** "Create Position" button navigates to `/portfolio-workspace` with no parameters. User must re-find company and re-select thesis. ~60 seconds of wasted effort.

**Alternatives:**
1. Pass context via query parameters (companyId, thesisId, conviction)
2. Pass context via route state
3. Open dialog inline on company page
4. Store context in global signal

**Arguments For (Option 1):**
- Simple, stateless, URL-shareable
- Works with go_router existing patterns
- No new state management needed
- User can bookmark/share pre-populated URLs

**Arguments Against (Option 1):**
- URL length limits (unlikely to hit)
- Query parameters visible in URL

**Final Choice:** Option 1 (Query parameters)

**Consequences:**
- `onCreatePosition` builds URI with query parameters
- Add Position dialog reads parameters on open
- Auto-fetches theses for pre-selected company
- Zero re-work for user

---

## Decision 3: Wire markReviewNeeded to Position Lifecycle

**Context:** `markReviewNeeded()` method exists in repository but is never called from UI. Review workflow is half-implemented.

**Alternatives:**
1. Add "Mark for Review" to position card menu
2. Auto-trigger on time-based threshold
3. Auto-trigger on thesis update
4. Remove the feature (dead code)

**Arguments For (Option 1):**
- User control over review timing
- Minimal implementation (menu item + provider method)
- Immediate visual feedback (warning border + badge)
- Consistent with existing PopupMenuButton pattern

**Arguments Against (Option 1):**
- Manual only (no automation)

**Final Choice:** Option 1 (Manual "Mark for Review")

**Consequences:**
- `markReviewNeeded()` method added to PortfolioWorkspaceProvider
- "Mark for Review" added to position card PopupMenuButton
- Position immediately gets warning border + "Review Needed" badge
- Count increments in header

---

## Decision 4: Add "Apply to New Research" on Lesson Cards

**Context:** Lessons tab shows lessons with no path back to company or thesis. Lessons are historical records, not active intelligence.

**Alternatives:**
1. "Apply to New Research" button → navigates to company Research tab
2. "Create New Thesis" button → opens thesis dialog with lesson context
3. "View Company" button (already exists) → user manually navigates to Research
4. Lesson linking to thesis fields

**Arguments For (Option 1):**
- Simple navigation to company Research tab
- User can create new thesis informed by lesson
- Minimal implementation (button + navigation)
- Closes learning → research loop

**Arguments Against (Option 1):**
- Doesn't pre-populate thesis dialog with lesson content
- User still needs to manually reference lesson

**Final Choice:** Option 1 (Navigate to company Research tab)

**Consequences:**
- `onNewResearch` callback added to `_LessonCard`
- "Apply to New Research" button with science icon
- Navigates to `/companies/${companyId}/research`
- Lessons become active intelligence, not dead-end records

---

## Decision 5: Company-First Lesson Cascade

**Context:** When surfacing lessons during thesis creation, what lessons are relevant?

**Alternatives:**
1. Same company + same stance → most relevant
2. Same company, any stance → company history
3. Same stance, different company → stance patterns
4. All lessons → global patterns
5. ML-based relevance ranking

**Arguments For (Option 1-4 cascade):**
- Company-specific lessons most actionable
- Stance patterns help calibrate confidence
- Global stats provide baseline context
- No ML complexity

**Arguments Against (Option 1-4 cascade):**
- May miss cross-company patterns
- No intelligent ranking

**Final Choice:** Prioritized cascade (1→2→3→4)

**Consequences:**
- Lessons sorted by relevance (company > stance > all)
- Micro-summaries at each level
- "Your prior bullish NVDA thesis was correct"
- "Your bullish theses are correct 65% of the time"

---

## Decision 6: Micro-summaries Over Dashboards

**Context:** How should lesson patterns be surfaced?

**Alternatives:**
1. Micro-summaries (inline text, 1-2 lines)
2. Mini-charts (sparklines, bar charts)
3. Separate analytics dashboard
4. Notification/toast

**Arguments For (Option 1):**
- Dense information, no decoration
- Consistent with terminal aesthetic
- No new chart dependencies
- Immediate comprehension

**Arguments Against (Option 1):**
- Limited visual appeal
- May miss complex patterns

**Final Choice:** Option 1 (Micro-summaries)

**Consequences:**
- "3 prior NVDA positions: 2 correct, 1 partial"
- "Your high-conviction theses: 70% correct"
- No new dependencies
- Consistent with design philosophy

---

## Decision 7: Passive Monitoring in MVP

**Context:** Should TAUG actively monitor metrics against invalidation thresholds?

**Alternatives:**
1. Passive monitoring (view-based, user visits thesis)
2. Active polling (Edge Function on cron)
3. Real-time monitoring (WebSocket)
4. No monitoring (manual only)

**Arguments For (Option 1):**
- No new infrastructure
- No API costs
- User sees breaches when they visit thesis
- Can upgrade to active later

**Arguments Against (Option 1):**
- User may miss breaches
- No proactive alerts

**Final Choice:** Option 1 (Passive monitoring)

**Consequences:**
- `assumption_check_v` view computes breach status
- Client fetches view when thesis is displayed
- Breach indicators shown inline
- Can add Edge Function cron later

---

## Decision 8: Thesis Lifecycle with Freshness

**Context:** Theses have no status field in Dart model. Research ages silently.

**Alternatives:**
1. Add `status` field (open/under_review/closed/archived)
2. Add `last_reviewed_at` column + compute freshness
3. Add both status and freshness
4. Keep current (no lifecycle)

**Arguments For (Option 3):**
- Status enables workflow transitions
- Freshness enables visual indicators
- "NEEDS REVIEW" section possible
- "Mark Reviewed" action possible

**Arguments Against (Option 3):**
- More schema changes
- More UI complexity

**Final Choice:** Option 3 (Status + freshness)

**Consequences:**
- `last_reviewed_at` column on `investment_theses`
- `researchFreshness` getter (fresh/aging/stale/expired)
- Status badge + freshness badge on thesis cards
- "NEEDS REVIEW" section in Research Workspace
- "Mark Reviewed" action resets freshness

---

## Decision 9: MVP Scope — P0 Only

**Context:** Research intelligence has 5 major features (Questions, Evidence, Invalidation, Lifecycle, Freshness). What ships first?

**Alternatives:**
1. P0 only (expose fields, freshness, Mark Reviewed)
2. P0 + P1 (add Questions, Assumptions, Conditions)
3. P0 + P1 + P2 (add Evidence linking, Reviews)
4. Everything at once

**Arguments For (Option 1):**
- Fastest to ship
- 60% of perceived intelligence upgrade
- No new tables (except `last_reviewed_at`)
- Can validate with users before building more

**Arguments Against (Option 1):**
- Missing structured invalidation
- Missing research questions

**Final Choice:** Option 1 (P0 only)

**Consequences:**
- 1 migration + 9 file modifications
- No new tables, no new pages
- Ships in 1-2 sprints
- Validates intelligence approach before deeper investment

---

## Decision 10: Deduplicate Stance Badges

**Context:** Three stance badge implementations exist: `_StanceBadge`, `_StanceChipSmall`, `_StanceChip`. Maintenance burden and inconsistency.

**Alternatives:**
1. Single `StanceBadge` widget with size enum
2. Keep separate implementations
3. Use existing `ConvictionBadge` pattern

**Arguments For (Option 1):**
- Single source of truth
- Consistent rendering
- -123 lines net reduction
- Easier to maintain

**Arguments Against (Option 1):**
- Breaking change for existing imports
- Need to update 4 files

**Final Choice:** Option 1 (Single `StanceBadge` widget)

**Consequences:**
- `StanceBadge` widget in `status_badges.dart`
- `StanceBadgeSize` enum (regular/small)
- Removed 3 private implementations
- Updated 4 files
- -123 lines net

---

*This log is continuously updated throughout execution.*
