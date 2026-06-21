# TAUG Screenshot Evidence Pack

**Date:** 2026-06-22
**Purpose:** Visual evidence of current product state.

---

## Required Screens

### 1. Companies Workspace

**What Works:**
- Company list with quality/freshness badges
- Search functionality
- Empty state with guidance

**What Fails:**
- No screenshots captured (code review only)

**Remaining Debt:**
- No actual screenshots

**Philosophy Violations:**
- None identified in code review

---

### 2. Company Workspace — Overview

**What Works:**
- DATA TRUST section with quality/freshness badges
- KEY METRICS with freshness indicators (colored borders)
- Decision prompts guide workflow
- Research status badge

**What Fails:**
- `dynamic` typing in overview_tab.dart (6 instances)
- Missing RepaintBoundary on some list items

**Remaining Debt:**
- Coarse-grained SignalBuilder reads 6 signals

**Philosophy Violations:**
- None (research-first layout)

---

### 3. Company Workspace — Financials

**What Works:**
- Restatement indicators (↺ icon with tooltip)
- Per-column freshness coloring (green/amber/red)
- Statement version badges (v2, v3)
- Dynamic provenance (not static "Source: SEC EDGAR")

**What Fails:**
- No screenshots captured (code review only)

**Remaining Debt:**
- Some hardcoded colors (Colors.grey)

**Philosophy Violations:**
- None (data trust layer)

---

### 4. Company Workspace — Research

**What Works:**
- Thesis dialog with all 10 fields
- Notes CRUD
- "Create Position" button on thesis (pre-populated dialog)
- Stance/conviction badges

**What Fails:**
- Lessons not surfaced during thesis creation (design pending)

**Remaining Debt:**
- Single thesis display (only first thesis shown)

**Philosophy Violations:**
- None (research workflow)

---

### 5. Portfolio Workspace — Active Positions

**What Works:**
- Active positions list with conviction/thesis badges
- "Mark for Review" action
- "View Company" navigation
- Return badges on closed positions

**What Fails:**
- `StatefulBuilder` anti-pattern in dialogs
- Direct `Supabase.instance.client` calls in UI

**Remaining Debt:**
- No RepaintBoundary on position cards

**Philosophy Violations:**
- None (decision tracking)

---

### 6. Portfolio Workspace — Closed Positions

**What Works:**
- Closed positions with return badges
- Outcome badges (correct/incorrect/partial)
- Thesis title display
- Lessons learned text

**What Fails:**
- No screenshots captured (code review only)

**Remaining Debt:**
- No lesson filtering/search

**Philosophy Violations:**
- None (outcome tracking)

---

### 7. Portfolio Workspace — Lessons

**What Works:**
- Lessons grouped by outcome
- Summary chips with counts
- "Apply to New Research" button (NEW)
- Lesson cards with company name, return %, outcome, lesson text

**What Fails:**
- Lessons not surfaced during thesis creation

**Remaining Debt:**
- No pattern recognition
- No conviction calibration

**Philosophy Violations:**
- Lessons are historical records, not active intelligence (partially fixed)

---

### 8. Dialogs — Thesis

**What Works:**
- All 10 fields capturable
- Stance/conviction chips
- Collapsible sections for optional fields

**What Fails:**
- Lessons not shown during creation

**Remaining Debt:**
- No evidence linking

**Philosophy Violations:**
- None

---

### 9. Dialogs — Add Position

**What Works:**
- Company search with autocomplete
- Thesis selector (pre-populated from thesis context)
- Conviction auto-populated from thesis
- Entry date picker
- Entry price field

**What Fails:**
- Direct `Supabase.instance.client` calls

**Remaining Debt:**
- Inline query (should use repository)

**Philosophy Violations:**
- None

---

### 10. Dialogs — Close Position

**What Works:**
- Outcome selection (correct/incorrect/partial)
- Exit price field
- Lessons learned field
- Dialog stays open on failure

**What Fails:**
- `StatefulBuilder` anti-pattern

**Remaining Debt:**
- None significant

**Philosophy Violations:**
- None

---

### 11. Dialogs — Quality Breakdown

**What Works:**
- 7 component scores with progress bars
- Color-coded (green/amber/red)
- Component details summary
- Scored date

**What Fails:**
- `BoxShadow` violates "borders over shadows" rule

**Remaining Debt:**
- None significant

**Philosophy Violations:**
- BoxShadow should be removed

---

### 12. Settings

**What Works:**
- Timezone selection
- Density mode selection

**What Fails:**
- Settings mutation errors have no UI surface

**Remaining Debt:**
- Density mode not consumed anywhere

**Philosophy Violations:**
- None

---

## Critical Issues Found

| Issue | Severity | Location |
|---|---|---|
| `StatefulBuilder` anti-pattern | Medium | portfolio_workspace_page.dart |
| Direct `Supabase.instance.client` in UI | Medium | portfolio_workspace_page.dart |
| `dynamic` typing | Medium | overview_tab.dart (6 instances) |
| Missing `RepaintBoundary` | Medium | 4 files |
| `BoxShadow` in quality popover | Low | quality_breakdown_popover.dart |

---

## What Works Well

| Pattern | Evidence |
|---|---|
| Consistent section headers | monoSection style throughout |
| ListView.builder with itemExtent | Portfolio, news, market, calendar |
| RepaintBoundary on metric cells | overview_tab.dart |
| Color-coded badges | Freshness, quality, conviction, stance |
| Clean empty states | AppEmptyState widget |
| Signal-based reactivity | SignalBuilder throughout |
| Decision prompts | Overview tab guides workflow |

---

## Screenshot Status

**Total Screens Required:** 12

**Screenshots Captured:** 0 (code review only)

**Status:** Checklist completed. Actual screenshots needed.

---

*This audit is maintained by QA-2 Agent.*
