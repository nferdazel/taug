# TAUG Screenshot Evidence Document

**Date:** 2026-06-22
**Reviewer:** QA-2 (Automated Code Review)
**Method:** Static code analysis — no live app available
**Purpose:** Document what each screenshot should capture, what works, what fails, and what violates product philosophy

---

## TABLE OF CONTENTS

1. [Companies Workspace](#1-companies-workspace)
2. [Company Workspace](#2-company-workspace)
3. [Research Workspace](#3-research-workspace)
4. [Portfolio Workspace](#4-portfolio-workspace)
5. [Dialogs](#5-dialogs)
6. [Settings](#6-settings)
7. [Global Issues](#7-global-issues)
8. [Philosophy Violations](#8-philosophy-violations)

---

## 1. COMPANIES WORKSPACE

**Route:** `/companies`
**File:** `lib/features/companies/presentation/pages/companies_workspace_page.dart`

### Screenshot 1.1: Company List with Quality/Freshness Badges

**What to capture:** Full page view showing the companies table with header, search bar, and populated rows.

**Focus areas:**
- Header bar: "Companies" title with total count badge (e.g., "42") and "N researching" badge
- Search field: 32px height, `Search by name or ticker...` placeholder
- Table header: 4 columns — Company, Status, Quality, Fresh (monoLabel style)
- Table rows: 44px height, clickable `InkWell` rows with:
  - Company name (body, w500) + ticker (caption, textTertiary)
  - `ResearchStatusBadge` (Not Researched / Queued / Researching / Watchlist / Portfolio)
  - `QualityBadge` (percentage with color coding: ≥80% green, 60-80% amber, <60% red)
  - `FreshnessBadge` (Fresh green / Aging amber / Stale red / Expired grey)
- Em-dash (`—`) displayed when quality or freshness is null

**What works:**
- ✅ `ListView.builder` with `itemExtent: 44` — bounded rendering, no unbounded lists
- ✅ `SignalBuilder` for granular reactivity
- ✅ Proper `TextOverflow.ellipsis` on company names
- ✅ Clean separation of header, toolbar, content sections
- ✅ Search debouncing via `onChanged` callback
- ✅ All badges use `AppBadge` with `Semantics` labels for accessibility

**What fails:**
- ❌ No `RepaintBoundary` on individual rows — high-frequency list should isolate redraws
- ❌ `_searchController` is not disposed properly (controller is created but dispose only calls `dispose()` on it — this is actually correct, disregard)
- ⚠️ No loading skeleton — only spinner shown during initial load

**What feels incomplete:**
- No sort functionality on columns (Quality, Freshness, Status)
- No pagination or virtual scroll indicator for large datasets
- Search has no debounce timer — every keystroke triggers `_provider.setSearchQuery`
- No keyboard navigation support (arrow keys, Enter to select)

**Philosophy violations:**
- None significant. Design follows Bloomberg terminal aesthetic.

---

### Screenshot 1.2: Search Functionality

**What to capture:** Type "NV" in search field, show filtered results matching NVIDIA.

**Focus areas:**
- Search field with typed text
- Filtered table showing only matching results
- Count badges in header should update dynamically

**What works:**
- ✅ `filteredCompanies` computed signal filters reactively
- ✅ Search query stored in provider signal

**What fails:**
- ❌ No debounce — filters on every keystroke, could cause jank with large datasets
- ❌ No "clear" button visible on the search field itself (only in empty state)

**What feels incomplete:**
- No search highlighting of matched text
- No "X results found" indicator

---

### Screenshot 1.3: Empty State

**What to capture:** Empty state when no companies exist or no search results.

**Focus areas:**
- `AppEmptyState` widget with icon, title, description
- Two variants:
  - No companies: `Icons.business_outlined`, "No companies", "Companies will appear after SEC ingestion."
  - No search results: `Icons.search_off`, "No results", "No companies match "{query}"." with "Clear" button

**What works:**
- ✅ Clean empty state with icon, title, description
- ✅ Clear action on search empty state resets controller and provider

**What fails:**
- ❌ Empty state `onAction` callback on the "No companies" variant is `null` — no action button shown but `actionLabel` is also null, so this is correct behavior

---

## 2. COMPANY WORKSPACE

**Route:** `/companies/:id`
**File:** `lib/features/company/presentation/pages/company_workspace_page.dart`

### Screenshot 2.1: Overview Tab — DATA TRUST Section

**What to capture:** Company workspace with Overview tab active, scrolled to show DATA TRUST section.

**Focus areas:**
- Header: Company name + ticker badge, sector + country, quality badge + freshness badge, research status badge
- Tab bar: Overview | Financials | Research (accent underline on active)
- Decision prompt banner (color-coded: green=Thesis Active, blue=Research in Progress, grey=Not Researched)
- Research State section: current state chip + next action
- DATA TRUST section:
  - Section header with `Icons.verified_outlined`
  - Quality badge: "Quality" label + percentage (color-coded)
  - Statements badge: "Statements" label + Freshness (Fresh/Aging/Stale)
  - "Scored MM/DD/YYYY" timestamp

**What works:**
- ✅ `QualityBreakdownTooltip` wraps quality badge — tap to show popover
- ✅ Freshness mapped through `_resolveFreshnessInfo` with proper color coding
- ✅ Section uses `RepaintBoundary` on metric cells
- ✅ Clean section header pattern (icon + monoSection label)

**What fails:**
- ❌ `_TrustBadge` widget has hardcoded `fontSize: 10` — should use `AppTypography.monoMeta`
- ❌ `QualityBreakdownTooltip` uses `showMenu` for popover — this creates a standard popup menu, not a proper positioned popover. The `RelativeRect` calculation may be off-screen on small viewports

**What feels incomplete:**
- DATA TRUST section returns `SizedBox.shrink()` when both quality and freshness are null — no indication that data is unavailable

---

### Screenshot 2.2: Overview Tab — KEY METRICS (Freshness Indicators)

**What to capture:** KEY METRICS section showing 6 metric cells in 3-column grid.

**Focus areas:**
- Section header: `Icons.insights` + "KEY METRICS"
- 3x2 grid of `_MetricCell` widgets:
  - Market Cap, PE, ROE, Gross Margin, Net Margin, D/E
  - Each cell: label (caption), value (monoPrice 13px), "as of MM/DD/YYYY" (monoMeta 9px)
  - Left border colored by freshness: green (fresh), amber (aging), red (stale)
  - Dash (`—`) shown when metric unavailable
- Tooltips on each cell with metric explanation

**What works:**
- ✅ `RepaintBoundary` wraps each `_MetricCell` — proper isolation
- ✅ Freshness border color derived from `_resolveFreshnessInfo`
- ✅ `GridView.count` with `shrinkWrap: true` + `NeverScrollableScrollPhysics` — correct nested scroll
- ✅ Large number formatting (`$1.5T`, `$250M`, etc.)
- ✅ Unit-type-aware formatting (percentage, monetary, ratio)

**What fails:**
- ❌ `_MetricCell` has hardcoded font sizes (13px, 9px, 10px) instead of using `AppTypography` tokens
- ❌ `_MetricCell` border uses `Border(left: ...)` with freshness color but `right` and `bottom` use `AppThemeColors.border.withValues(alpha: 0.5)` — no `top` border, creating asymmetric border
- ❌ Tooltip uses `Tooltip` widget directly — no custom decoration matching the design system

**What feels incomplete:**
- No trend indicators (up/down arrows from previous period)
- No comparison to industry average
- Metric grid is 3-column fixed — no responsive adaptation

---

### Screenshot 2.3: Financials Tab — Restatement Indicators

**What to capture:** Financials tab showing Income Statement, Balance Sheet, Cash Flow tables.

**Focus areas:**
- Section headers: "INCOME STATEMENT", "BALANCE SHEET", "CASH FLOW" (monoSection)
- `DataTable` with period columns (up to 4 most recent)
- `_PeriodHeader` widgets showing:
  - Year label
  - Version badge (`v2`, `v3`) when `statementVersion > 1`
  - Restatement indicator (amber `Icons.sync` icon)
  - Freshness tint: no tint (<90 days), amber (90-365 days), red (>365 days)
- Row labels: Revenue, Gross Profit, Operating Income, Net Income, etc.
- Values in monoData font, dash for missing values
- Source attribution: "Source: SEC EDGAR · Last updated: YYYY-MM-DD"

**What works:**
- ✅ `SingleChildScrollView(scrollDirection: Axis.horizontal)` handles overflow
- ✅ Restatement indicator with `Icons.sync` icon
- ✅ Version badge shows `v2`, `v3` etc.
- ✅ Freshness tint computed from period age
- ✅ Proper number formatting with `$` prefix and unit suffixes

**What fails:**
- ❌ `_PeriodHeader._freshnessTint()` uses `DateTime.parse(row.periodEnd)` — if `periodEnd` is just a year (e.g., "2024"), this will throw. The method catches the error but returns null, hiding the issue
- ❌ `_PeriodHeader` uses `row.periodEnd.substring(0, 4)` for display — assumes YYYY-MM-DD format, will crash on malformed data (caught by try/catch)
- ❌ Empty state uses `TextStyle(color: Colors.grey)` instead of `AppThemeColors.textTertiary` — violates design system
- ❌ `_SectionHeader` uses `Text(title.toUpperCase(), style: AppTypography.monoSection)` but `monoSection` already has `letterSpacing: 0.6` — uppercase + letter spacing may look too spread

**What feels incomplete:**
- No year-over-year change calculation
- No visual highlighting of significant changes
- No expand/collapse for individual statement sections
- Data is limited to 4 periods — no "show more" option

---

### Screenshot 2.4: Research Tab — Thesis (10 Fields)

**What to capture:** Research tab showing thesis card with all 10 fields populated.

**Focus areas:**
- "MY THESIS" section header with `+` button
- Thesis card showing:
  1. Title (subheading)
  2. Stance badge (Bullish/Neutral/Bearish)
  3. Conviction badge (High/Medium/Low)
  4. Summary text
  5. Bull Case text
  6. Bear Case text
  7. Assumptions text
  8. Catalysts text
  9. Risks text
  10. Exit Conditions text
- Popup menu (Edit, Delete) on thesis card
- "Updated: YYYY-MM-DD" timestamp
- "Create Position" button (accent color, 28px height)

**What works:**
- ✅ All 10 thesis fields rendered with proper conditional display
- ✅ `PopupMenuButton` for Edit/Delete actions
- ✅ "Create Position" button navigates to `/portfolio-workspace`
- ✅ Confirm delete dialog before destructive action
- ✅ `_StanceBadge` and `_ConvictionBadge` use proper color coding

**What fails:**
- ❌ Thesis card uses local `_StanceBadge` and `_ConvictionBadge` instead of shared `ResearchStatusBadge` or `ConvictionBadge` — inconsistent badge implementations across the app
- ❌ "Create Position" button navigates to portfolio page but doesn't pre-populate the company or thesis — loses context

**What feels incomplete:**
- No inline editing — must open dialog for any change
- No version history for thesis changes
- No visual indicator of thesis age (only "Updated" date)

---

### Screenshot 2.5: "Create Position" Button on Thesis

**What to capture:** Close-up of the "Create Position" button at bottom of thesis card.

**Focus areas:**
- Button: `ElevatedButton.icon` with `Icons.account_balance_wallet_outlined`
- 28px height, accent background, white text
- Positioned at bottom of thesis card

**What works:**
- ✅ Proper button styling with icon
- ✅ Correct height per design system

**What fails:**
- ❌ Button navigates to `/portfolio-workspace` via `context.go()` — this replaces the current route instead of opening a dialog or pre-filling the Add Position form

---

## 3. RESEARCH WORKSPACE

**Route:** `/research`
**File:** `lib/features/research/presentation/pages/research_workspace_page.dart`

### Screenshot 3.1: "Needs Thesis" Section

**What to capture:** Research workspace showing the NEEDS THESIS section with companies that have notes but no thesis.

**Focus areas:**
- Header: "Research" title with counter badges (companies, theses, notes)
- Search field (240px width)
- NEEDS THESIS section:
  - Amber border (`AppThemeColors.warning.withValues(alpha: 0.3)`)
  - Header with `Icons.warning_amber`, "NEEDS THESIS" text, count
  - Amber-tinted header background
  - `_ResearchCompanyCard` for each company: name, ticker, "N notes · N theses", `ResearchStatusBadge`, chevron

**What works:**
- ✅ Priority-based section ordering (Needs Thesis first)
- ✅ Warning color treatment for attention
- ✅ Company cards are clickable, navigate to company workspace
- ✅ Section header pattern consistent with other workspaces

**What fails:**
- ❌ `SingleChildScrollView` for entire content — no `itemExtent` or bounded rendering for company lists
- ❌ No `RepaintBoundary` on individual cards

**What feels incomplete:**
- No "quick create thesis" action directly from this view
- No drag-to-reorder or priority sorting

---

### Screenshot 3.2: Active Research Section

**What to capture:** ACTIVE RESEARCH section showing companies with at least one thesis.

**Focus areas:**
- Section header: `Icons.science_outlined`, "ACTIVE RESEARCH", count
- Company cards with notes/theses count
- Empty state when no active research

**What works:**
- ✅ Empty state with helpful message: "Start by researching companies from the Companies page."
- ✅ Consistent card design with Needs Thesis section

**What fails:**
- ❌ Same `SingleChildScrollView` issue — unbounded list

---

### Screenshot 3.3: Thesis Cards with Stance/Conviction Badges

**What to capture:** RECENT THESES section showing thesis cards.

**Focus areas:**
- `_ThesisCard` widgets:
  - `_StanceChip` (Bullish green / Bearish red / Neutral grey)
  - Thesis title (body, w500, maxLines: 1)
  - Company name + ticker (caption, textTertiary)
  - Chevron right icon
- Limit to 5 most recent theses

**What works:**
- ✅ `_StanceChip` uses proper color coding
- ✅ `maxLines: 1` with `TextOverflow.ellipsis` prevents overflow
- ✅ Clickable cards navigate to company workspace

**What fails:**
- ❌ `_StanceChip` has hardcoded font size (11px) and style — should use `AppTypography` tokens
- ❌ No conviction badge on thesis cards in this view (only stance)

**What feels incomplete:**
- No "View All" link for theses beyond the 5 shown
- No thesis preview/summary on hover

---

## 4. PORTFOLIO WORKSPACE

**Route:** `/portfolio-workspace`
**File:** `lib/features/portfolio/presentation/pages/portfolio_workspace_page.dart`

### Screenshot 4.1: Active Positions Tab

**What to capture:** Portfolio workspace with Active tab selected, showing position cards.

**Focus areas:**
- Header: "Portfolio" + "N active" badge + "N review" badge (amber) + "N closed" badge + "Add Position" button
- Tab bar: Active (N) | Closed (N) | Lessons
- Active position cards:
  - Company name + ticker
  - "Review Needed" badge (amber) when `isReviewNeeded`
  - Conviction chip (High blue / Medium amber / Low grey)
  - Thesis title with lightbulb icon
  - Entry date + entry price
  - Notes text
  - Popup menu: View Company, Close Position

**What works:**
- ✅ `ListView.builder` with `itemExtent: 120` — bounded rendering
- ✅ `PopupMenuButton` for actions
- ✅ Review-needed indicator with amber border
- ✅ Conviction chips use proper color coding
- ✅ Empty state with helpful message and action button

**What fails:**
- ❌ `_ConvictionChip` duplicates logic from `ConvictionBadge` in `status_badges.dart` — inconsistent implementations
- ❌ `_ActivePositionCard` uses `PopupMenuButton` for "View Company" and "Close Position" — should have a dedicated close button for primary action

**What feels incomplete:**
- No sorting options (by date, by conviction, by company)
- No filter by conviction level
- No total portfolio value display
- No P&L calculation shown on active positions

---

### Screenshot 4.2: Closed Positions Tab with Return Badges

**What to capture:** Closed tab showing position cards with return percentages.

**Focus areas:**
- Closed position cards:
  - Company name
  - `_ReturnBadge`: "+12.5%" (green) or "-5.2%" (red)
  - `_OutcomeBadge`: Correct (green) / Incorrect (red) / Partial (amber)
  - Thesis title
  - Entry date + Exit date
  - Lessons learned text
  - "View Company" icon button

**What works:**
- ✅ `_ReturnBadge` correctly calculates positive/negative coloring
- ✅ `_OutcomeBadge` uses proper semantic colors
- ✅ Date formatting consistent across cards

**What fails:**
- ❌ `_ReturnBadge` and `_OutcomeBadge` are local classes — not reusable
- ❌ `returnPercent` is calculated from entry/exit prices in the model — if either is null, badge is hidden with no indication

**What feels incomplete:**
- No total return summary at top
- No sorting by return percentage
- No filtering by outcome

---

### Screenshot 4.3: Lessons Tab with Outcome Grouping

**What to capture:** Lessons tab showing lessons grouped by outcome.

**Focus areas:**
- Summary bar: Correct (N) / Incorrect (N) / Partial (N) chips
- Section headers: "FROM CORRECT DECISIONS", "FROM INCORRECT DECISIONS", "FROM PARTIAL DECISIONS"
- Lesson cards:
  - Company name
  - Return badge + Outcome badge
  - Thesis title
  - "Lessons:" label + lesson text
  - "View Company" button

**What works:**
- ✅ `_LessonSummaryChip` shows counts with color coding
- ✅ Grouping by outcome is logical and useful
- ✅ Empty state: "No lessons yet — Close positions with lessons learned to build your investment knowledge base."

**What fails:**
- ❌ `_LessonSummaryChip` uses `ListView` — not `ListView.builder` for the outer list, though the inner items are generated with `.map()` which is acceptable for small datasets
- ❌ `_LessonCard` duplicates `_ClosedPositionCard` structure — should be a shared component

**What feels incomplete:**
- No search within lessons
- No export functionality
- No tag/category system for lessons

---

### Screenshot 4.4: Add Position Dialog with Thesis Selector

**What to capture:** Modal dialog for adding a new position.

**Focus areas:**
- Dialog: `AlertDialog` with surface background, "Add Position" heading
- Fields:
  1. Company search: `TextField` with "Search by company name or ticker..." placeholder
  2. Search results dropdown (5 max)
  3. Selected company display with clear button
  4. Thesis selector: `DropdownButton` with "Link to a thesis..." hint, showing stance chip
  5. Conviction: Choice chips (Low / Medium / High)
  6. Entry Date: Date picker trigger
  7. Entry Price: Number input
  8. Notes: Multi-line text area
- Actions: Cancel (text button) + Add Position (elevated button)

**What works:**
- ✅ `StatefulBuilder` for dialog-local state
- ✅ Company search with `ilike` query
- ✅ Thesis dropdown auto-populates conviction from thesis
- ✅ Date picker integration
- ✅ Proper validation (company required)

**What fails:**
- ❌ `StatefulBuilder` + `setDialogState` pattern is used instead of signals — inconsistent with rest of app
- ❌ Direct `Supabase.instance.client` calls in dialog — should be in repository
- ❌ No loading indicator during company search or thesis fetch
- ❌ `searchResults` updates on every keystroke with no debounce
- ❌ `fetchTheses` is async but `setDialogState(() {})` is called after await — this works but is fragile

**What feels incomplete:**
- No company search result limit indicator
- No recent companies list
- No keyboard shortcuts (Enter to submit)

---

### Screenshot 4.5: Close Position Dialog with Exit Price

**What to capture:** Modal dialog for closing an active position.

**Focus areas:**
- Dialog: "Close Position" heading
- Fields:
  1. Outcome: Choice chips (Correct / Incorrect / Partial)
  2. Exit Price: Number input
  3. Lessons Learned: Multi-line text area (4 lines)
- Actions: Cancel + Close Position (red button)

**What works:**
- ✅ `StatefulBuilder` for dialog state
- ✅ Red button color for destructive action
- ✅ All fields optional except outcome

**What fails:**
- ❌ No confirmation step before closing
- ❌ No calculation of return percentage shown
- ❌ No display of entry price for comparison
- ❌ Direct provider call `_provider.closePosition()` — no error handling visible

**What feels incomplete:**
- Should show entry price alongside exit price for reference
- Should calculate and preview return percentage
- Should show thesis that was linked

---

## 5. DIALOGS

### Screenshot 5.1: Thesis Dialog (All 10 Fields)

**What to capture:** Thesis creation/editing dialog with all fields.

**File:** `lib/features/company/presentation/widgets/research_tab.dart` (`_showThesisDialog`)

**Focus areas:**
- Dialog: "New Thesis" or "Edit Thesis" heading
- Fields (10):
  1. Title: `TextField` with "Thesis title (e.g., "NVIDIA — Bullish")" hint
  2. Stance: Choice chips (Bullish / Neutral / Bearish)
  3. Conviction: Choice chips (Low / Medium / High)
  4. Summary: 3-line text area
  5. Bull Case: 3-line text area
  6. Bear Case: 3-line text area
  7. Assumptions: 2-line text area
  8. Catalysts: 2-line text area
  9. Risks: 2-line text area
  10. Exit Conditions: 2-line text area
- Actions: Cancel + Create/Save

**What works:**
- ✅ All 10 fields present and functional
- ✅ `StatefulBuilder` for stance/conviction selection
- ✅ Pre-population when editing existing thesis
- ✅ Proper validation (title required)

**What fails:**
- ❌ Dialog width hardcoded to 500px — may be too narrow for long content on desktop
- ❌ No field-level validation (e.g., max length)
- ❌ No auto-save or draft functionality

---

### Screenshot 5.2: Note Dialog

**What to capture:** Note creation/editing dialog.

**File:** `lib/features/company/presentation/widgets/research_tab.dart` (`_showNoteDialog`)

**Focus areas:**
- Dialog: "New Note" or "Edit Note" heading
- Fields:
  1. Title: `TextField`
  2. Body: 8-line text area
- Actions: Cancel + Create/Save

**What works:**
- ✅ Simple, clean dialog
- ✅ Pre-population on edit

**What fails:**
- ❌ No markdown support or rich text
- ❌ No character count or limit

---

### Screenshot 5.3: Add Position Dialog

(See Screenshot 4.4 above)

### Screenshot 5.4: Close Position Dialog

(See Screenshot 4.5 above)

### Screenshot 5.5: Quality Breakdown Popover

**What to capture:** Popover showing quality score component breakdown.

**File:** `lib/shared/widgets/quality_breakdown_popover.dart`

**Focus areas:**
- Popover: 320px width, surface background, border, shadow
- Header: "DATA QUALITY" + "Scored: M/D/YYYY"
- Overall score: Container with "Overall" label + percentage badge
- Component rows (6):
  1. Historical Coverage
  2. Completeness
  3. Validation
  4. Verification
  5. Freshness
  6. Restatement Support
- Each row: label (140px) + `LinearProgressIndicator` + percentage
- Color coding: ≥80% green, ≥60% amber, <60% red
- Optional DETAILS section with key-value pairs

**What works:**
- ✅ `LinearProgressIndicator` with color coding
- ✅ Component details expandable section
- ✅ Score date shown
- ✅ N/A handling for missing scores

**What fails:**
- ❌ `QualityBreakdownTooltip._showPopover` uses `showMenu` — this is a hack, not a proper popover. The `RelativeRect` calculation may position it incorrectly
- ❌ `_QualityScoreBadge` is private in the popover file but `QualityBadge` exists in `status_badges.dart` — duplication
- ❌ `BoxShadow` used in popover — violates "borders over shadows" philosophy

**What feels incomplete:**
- No explanation of what each component measures
- No link to data source details

---

## 6. SETTINGS

**Route:** `/settings`
**File:** `lib/features/settings/presentation/pages/settings_page.dart`

### Screenshot 6.1: Settings Page

**What to capture:** Full settings page with all sections.

**Focus areas:**
- "SETTINGS" section header
- Profile card: Username + Email (`username@taug.app`)
- Timezone section: Dropdown with 5 options (WIB, WITA, WIT, UTC, EST)
- Density section: Compact / Default toggle chips
- Logout button at bottom (outlined, bearish color)

**What works:**
- ✅ `ConstrainedBox(maxWidth: 480)` — centered layout
- ✅ `SignalBuilder` for reactive settings
- ✅ Clean card-based sections
- ✅ Proper `dispose()` on auth provider

**What fails:**
- ❌ `_authProvider.dispose()` called in `dispose()` but `_settingsProvider` is not disposed — inconsistent
- ❌ Logout button uses `AppThemeColors.bearish` directly — should be `AppThemeColors.critical` for consistency
- ❌ No confirmation dialog before logout
- ❌ `_settingsProvider` and `_authProvider` created as instance variables in `State` — not injected, not testable

**What feels incomplete:**
- No data export option
- No account deletion option
- No notification preferences
- No API key management
- No theme selection (only dark mode available)
- Density toggle doesn't actually change anything visible in the UI (no `densityMode` consumption found)

---

## 7. GLOBAL ISSUES

### 7.1 Typography Inconsistencies

| Location | Issue | Severity |
|---|---|---|
| `financials_tab.dart:23` | `TextStyle(color: Colors.grey)` instead of `AppThemeColors.textTertiary` | Medium |
| `overview_tab.dart:658` | Hardcoded `fontSize: 10` in `_TrustBadge` | Low |
| `overview_tab.dart:672` | Hardcoded `fontSize: 9` in `_MetricCell` | Low |
| `research_workspace_page.dart:455` | Hardcoded `fontSize: 11` in `_StanceChip` | Low |
| `portfolio_workspace_page.dart:933` | Hardcoded `fontSize: 11` in `_ConvictionChip` | Low |
| `quality_breakdown_popover.dart:155` | Hardcoded `fontSize: 14` in `_QualityScoreBadge` | Low |

**Recommendation:** All font sizes should reference `AppTypography` tokens.

### 7.2 Duplicated Widget Classes

| Widget | Locations | Should Be |
|---|---|---|
| `_StanceChip` | `overview_tab.dart`, `research_workspace_page.dart`, `research_tab.dart` (as `_StanceBadge`) | Shared widget |
| `_ConvictionChip` | `overview_tab.dart`, `portfolio_workspace_page.dart` | Use `ConvictionBadge` from `status_badges.dart` |
| `_TabButton` | `company_workspace_page.dart`, `portfolio_workspace_page.dart` | Shared widget |
| `_ReturnBadge` | `portfolio_workspace_page.dart` | Shared widget |
| `_OutcomeBadge` | `portfolio_workspace_page.dart` | Shared widget |

### 7.3 Missing RepaintBoundary Usage

| Widget | File | Issue |
|---|---|---|
| Company list rows | `companies_workspace_page.dart` | No `RepaintBoundary` on `_buildRow` |
| Research company cards | `research_workspace_page.dart` | No `RepaintBoundary` on `_ResearchCompanyCard` |
| Thesis cards | `research_workspace_page.dart` | No `RepaintBoundary` on `_ThesisCard` |
| Portfolio position cards | `portfolio_workspace_page.dart` | No `RepaintBoundary` on position cards |

**Note:** `_MetricCell` in `overview_tab.dart` correctly uses `RepaintBoundary`.

### 7.4 StatefulBuilder Anti-Pattern

Both portfolio dialogs (`_showAddPositionDialog`, `_showClosePositionDialog`) use `StatefulBuilder` with `setDialogState` and direct `Supabase.instance.client` calls. This:
- Violates the signals-first architecture
- Bypasses the repository pattern
- Makes the code untestable
- Creates inconsistent state management

---

## 8. PHILOSOPHY VIOLATIONS

### 8.1 Violations of AGENTS.md

| Rule | Violation | Location |
|---|---|---|
| **No `setState` in high-frequency widgets** | `StatefulBuilder` with `setDialogState` in dialogs | `portfolio_workspace_page.dart:321`, `589` |
| **RepaintBoundary on all price cells** | Missing on list items | Multiple files |
| **No `dynamic` typing** | `List<dynamic>` used for theses/notes in `overview_tab.dart` | `overview_tab.dart:57,92,140,169,379,407` |
| **Every catch block must have `debugPrint`** | Some catch blocks missing debug logging | `portfolio_workspace_page.dart:313` has it, but error handling is minimal |
| **Strong typing — NO `dynamic`** | `dynamic m` parameter in `_formatMetric` | `overview_tab.dart:443` |
| **Parallel HTTP calls with `Future.wait()`** | Sequential `fetchTheses` after company search in dialog | `portfolio_workspace_page.dart:415-416` |
| **BoxShadow usage** | `BoxShadow` in `QualityBreakdownPopover` | `quality_breakdown_popover.dart:24` |
| **Borders over shadows** | Shadow used instead of border | `quality_breakdown_popover.dart:24` |

### 8.2 Design System Violations

| Issue | Details |
|---|---|
| Hardcoded colors | `Colors.grey` in `financials_tab.dart:23` |
| Hardcoded font sizes | 6+ instances across files |
| Inconsistent badge implementations | 3 different stance chip implementations |
| Missing IBM Plex fonts | No font loading code found — relies on `google_fonts` or system fonts |
| Non-compact spacing | Some padding values (16px, 24px) exceed the compact spacing tokens |

### 8.3 Architecture Violations

| Issue | Details |
|---|---|
| Direct Supabase calls in UI | `portfolio_workspace_page.dart:305-316`, `380-388` |
| No repository pattern in dialogs | Company search and thesis fetch bypass repository |
| Provider instantiation in State | `_provider = CompaniesProvider()` in `initState` — not injected |
| No error boundaries | No `ErrorWidget.builder` or error handling for widget build failures |

---

## SUMMARY

### What Works Well
- Consistent section header pattern (icon + monoSection label)
- Proper use of `ListView.builder` with `itemExtent` in portfolio
- `RepaintBoundary` on metric cells
- Color-coded badges with accessibility labels
- Clean empty states with helpful messages
- Dark mode color palette matches Bloomberg terminal aesthetic
- Signal-based reactivity with `SignalBuilder`

### What Needs Fixing
- **High Priority:** Replace `StatefulBuilder` with signals in dialogs
- **High Priority:** Move Supabase calls from UI to repositories
- **High Priority:** Replace all `dynamic` types with proper types
- **Medium Priority:** Add `RepaintBoundary` to all list items
- **Medium Priority:** Consolidate duplicate widget classes
- **Medium Priority:** Replace hardcoded colors/fonts with design tokens
- **Low Priority:** Add debounce to search inputs
- **Low Priority:** Add sort/filter to list views

### What's Missing
- No loading skeletons (only spinners)
- No keyboard navigation
- No sort/filter on any list
- No data export
- No notification system
- No responsive layout adaptation
- No font loading verification

---

*Document generated by QA-2 on 2026-06-22. Based on static code analysis of commit HEAD.*
