# C6 — Companies Workspace MVP

**Date:** 2026-06-20
**Type:** Implementation plan — no code
**Perspective:** Product Engineer + Flutter Web Developer + Research Product Designer

---

## Executive Summary

Companies Workspace is the entry point. Users discover companies, assess data quality, and enter Company Workspace for deep research. The MVP is a searchable company table with quality indicators and quick actions. Nothing more.

**Core purpose:** "Show me the companies. Let me find the one I want to research."

---

## Workspace Purpose

### Why This Page Exists

Users need a starting point. They know they want to research companies, but they need to:
1. See what's available (32 companies)
2. Find a specific company (search)
3. Assess data quality at a glance (quality badge)
4. Enter Company Workspace (click)

### How It Connects

```
Companies Workspace
├── → Company Workspace (click company row)
├── → Research Queue (add company to queue)
├── → Company List (browse all companies)
└── → Portfolio (future: add to portfolio)
```

**Key insight:** Companies Workspace is a launcher, not a destination. Users spend <30 seconds here before entering Company Workspace.

---

## MVP Scope

### MUST HAVE

| Feature | Rationale |
|---|---|
| Company table | Core component — displays all companies |
| Company name + ticker | Identity columns |
| Sector | Classification column |
| Quality badge | Trust indicator |
| Freshness badge | Data freshness indicator |
| Click → Company Workspace | Navigation to destination |
| Search (ticker + name) | Find specific company |
| Empty state | Handle no-data scenario |

### SHOULD HAVE

| Feature | Rationale |
|---|---|
| Market Cap column | Scale context |
| Research status indicator | Shows if company has notes/thesis |
| Add to Research Queue | Quick action |
| Sort by any column | Data exploration |
| Keyboard navigation | Desktop UX |

### DO NOT BUILD YET

| Feature | Reason |
|---|---|
| Advanced filters | Screener functionality — post-MVP |
| Column visibility toggle | Table customization — post-MVP |
| Comparison selection | Comparison — post-MVP |
| Bulk actions | Batch operations — post-MVP |
| Export | Data export — post-MVP |

---

## Layout

### Page Structure

```
┌─────────────────────────────────────────────────────────────┐
│ Companies                                                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ 🔍 Search companies...                    [Sector ▼] [Sort ▼]│
│                                                               │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ Company     │ Ticker │ Sector    │ Quality │ Fresh │ Queue ││
│ ├─────────────┼────────┼───────────┼─────────┼───────┼───────┤│
│ │ Apple Inc.  │ AAPL   │ Tech      │ 🟢 83%  │ 🟢    │ [+]  ││
│ │ NVIDIA Corp │ NVDA   │ Tech      │ 🟢 83%  │ 🟢    │ [+]  ││
│ │ Microsoft   │ MSFT   │ Tech      │ 🟡 73%  │ 🟢    │ [+]  ││
│ │ Amazon      │ AMZN   │ Consumer  │ 🟡 73%  │ 🟢    │ [+]  ││
│ │ Alphabet    │ GOOGL  │ Tech      │ 🟡 73%  │ 🟢    │ [+]  ││
│ │ ...         │        │           │         │       │       ││
│ └───────────────────────────────────────────────────────────┘ │
│                                                               │
│ 32 companies                          [Page 1] [2] [3] [Next]│
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Regions

| Region | Height | Content |
|---|---|---|
| Header | Auto | Page title |
| Toolbar | 40px | Search + filters |
| Table | Fill | Company rows |
| Footer | 32px | Pagination |

---

## Company Table

### MVP Columns

| Column | Width | Alignment | Sortable | Purpose |
|---|---|---|---|---|
| Company | 200px | Left | ✅ | Name + ticker |
| Sector | 120px | Left | ✅ | Industry classification |
| Quality | 80px | Center | ✅ | Quality badge |
| Fresh | 60px | Center | ✅ | Freshness badge |
| Queue | 40px | Center | — | Add to research queue |

### Column Details

**Company Column:**
```
┌──────────────────────────┐
│ Apple Inc.               │
│ AAPL                     │
└──────────────────────────┘
```
- Line 1: Company name (bold, 13px)
- Line 2: Ticker (secondary, 11px)
- Click → Company Workspace

**Sector Column:**
```
Technology
```
- Sector name (12px)
- Future: color-coded by sector

**Quality Column:**
```
🟢 83%
```
- Quality badge (C1 component)
- Green ≥80%, Yellow 60-80%, Red <60%

**Fresh Column:**
```
🟢
```
- Freshness dot (C1 component)
- Green = fresh, Yellow = aging, Red = stale

**Queue Column:**
```
[+]
```
- Add to Research Queue button
- Icon only, tooltip "Add to Research Queue"
- Toggles to ✓ when already in queue

### Table Behavior

| Behavior | Implementation |
|---|---|
| Sort | Click column header |
| Search | Filter by name/ticker |
| Click row | Navigate to Company Workspace |
| Keyboard | Arrow keys + Enter |

---

## Research Status System

### Status Definitions

| Status | Visual | Meaning |
|---|---|---|
| Not Researched | — (empty) | No notes, no thesis |
| In Queue | 📋 icon | Added to Research Queue |
| Has Notes | 📝 icon | Company has research notes |
| Has Thesis | 💡 icon | Company has investment thesis |
| In Portfolio | 📊 icon | Company is a portfolio position |

### Display

Research status is NOT an MVP column in the table (too complex). Instead:
- Quality badge indicates data completeness
- Freshness badge indicates data freshness
- Research status is visible only in Company Workspace

**MVP decision:** No research status column in Companies table. Keep the table focused on discovery, not research status.

---

## Search Experience

### MVP Search

```
┌──────────────────────────────────────────┐
│ 🔍 NVDA                                  │
├──────────────────────────────────────────┤
│ NVIDIA Corp · NVDA · Technology          │
│ [Open] [Add to Queue]                    │
└──────────────────────────────────────────┘
```

### Search Behavior

| Input | Behavior |
|---|---|
| Ticker (e.g., "NVDA") | Filters table to matching ticker |
| Name (e.g., "NVIDIA") | Filters table to matching name |
| Partial match | "NV" matches "NVDA" |
| Empty | Shows all companies |
| No results | Shows empty state |

### Keyboard Behavior

| Key | Action |
|---|---|
| `/` | Focus search field |
| `Escape` | Clear search, return to table |
| `Enter` | Navigate to first result |
| `↑↓` | Navigate results |

---

## Quick Actions

### MVP Quick Actions

| Action | Location | Behavior |
|---|---|---|
| Add to Queue | Queue column [+] | Add company to Research Queue |
| Open Company | Click row | Navigate to Company Workspace |

**That's it.** No bulk actions, no comparison, no export. Keep it minimal.

---

## Empty States

### No Companies

```
┌─────────────────────────────────────────┐
│                                          │
│        📊 No Companies Available         │
│                                          │
│   Data sync hasn't run yet.             │
│   Companies will appear after the        │
│   first SEC ingestion completes.         │
│                                          │
└─────────────────────────────────────────┘
```

### No Search Results

```
┌─────────────────────────────────────────┐
│                                          │
│        🔍 No Results Found               │
│                                          │
│   No companies match "XYZ".             │
│   Try a different search term.           │
│                                          │
│         [Clear Search]                   │
└─────────────────────────────────────────┘
```

### No Research Queue (separate page)

```
┌─────────────────────────────────────────┐
│                                          │
│        📋 Research Queue Empty            │
│                                          │
│   Add companies from the Companies       │
│   page to start your research.           │
│                                          │
│         [Browse Companies]               │
└─────────────────────────────────────────┘
```

---

## Data Requirements

### Required Backend Fields

| Field | Source | Required |
|---|---|---|
| `company_id` | `companies.id` | ✅ |
| `display_name` | `companies.display_name` | ✅ |
| `ticker` | `securities.ticker` | ✅ |
| `sector` | `sectors.name` (via `companies.primary_sector_id`) | ⚠️ NULL for some |
| `quality_score` | `data_quality_scores.overall_score` | ✅ |
| `freshness_status` | `company_freshness_v.statement_freshness` | ✅ |

### Data Query

```dart
// Supabase query for company list
final response = await client
    .from('companies')
    .select('''
      id, display_name,
      sectors:primary_sector_id (name),
      securities!inner (ticker)
    ''')
    .eq('ingestion_enabled', true)
    .order('display_name');
```

### Quality + Freshness Join

```dart
// Separate queries for quality and freshness (avoid complex joins)
final qualityScores = await client
    .from('data_quality_scores')
    .select('company_id, overall_score')
    .order('score_date', ascending: false);

final freshness = await client
    .from('company_freshness_v')
    .select('company_id, statement_freshness');
```

---

## Implementation Order

### Step 1: Workspace Shell (2 hours)

```
lib/features/companies/
└── presentation/
    └── pages/
        └── companies_page.dart
```

- Page scaffold with header
- Empty body (placeholder)

### Step 2: Data Layer (2 hours)

```
lib/features/companies/
├── data/
│   ├── company_list_repository.dart
│   └── company_list_models.dart
```

- Repository fetching company list with sectors + tickers
- Quality score query
- Freshness query
- Signals for data state

### Step 3: Company Table (3 hours)

```
lib/features/companies/
└── presentation/
    └── widgets/
        ├── company_table.dart
        └── company_table_row.dart
```

- DataTable with 5 columns
- Click handler → Company Workspace
- Sort by column

### Step 4: Search (1 hour)

```
lib/features/companies/
└── presentation/
    └── widgets/
        └── company_search.dart
```

- Search field above table
- Filter logic (name/ticker match)
- Keyboard shortcuts (/ and Escape)

### Step 5: Quality + Freshness Badges (1 hour)

- Integrate C1 badge components
- Display in table columns

### Step 6: Research Queue Action (1 hour)

- Add [+] button in Queue column
- Toggle to ✓ when in queue
- Connect to watchlist repository

### Step 7: Empty/Loading/Error States (1 hour)

- Integrate C5 state components
- Show appropriate state for each scenario

### Step 8: Polish (1 hour)

- Responsive layout
- Keyboard navigation
- Loading indicators

### Total: ~12 focused hours (~2 days)

---

## Done Criteria

Companies Workspace is complete when:

| Criterion | Verification |
|---|---|
| Company table renders | 32 companies displayed |
| Search works | Type "NVDA" → shows NVIDIA |
| Quality badges display | Green/yellow/red badges visible |
| Freshness badges display | Freshness dots visible |
| Click → Company Workspace | Navigates correctly |
| Add to Queue works | Company added to research queue |
| Empty state works | Shows when no search results |
| Sort works | Click column header sorts |
| Keyboard navigation | /, Escape, Enter, arrows work |

After Companies Workspace: Company Workspace implementation begins.

---

## Risks

### Table Performance

**Risk:** 32+ rows with badges may be slow on Web.

**Mitigation:** DataTable handles 32 rows easily. Test with 100+ rows for future proofing.

### Search Complexity

**Risk:** Search implementation may be more complex than expected.

**Mitigation:** Simple string matching. No fuzzy search in MVP.

### Sector Data Missing

**Risk:** Some companies have NULL sector.

**Mitigation:** Show "—" for missing sector. Don't block on this.

### Queue State Management

**Risk:** Queue state needs to persist across page navigations.

**Mitigation:** Use signals + Supabase for persistence.

---

## Recommendation

1. **Companies Workspace is a launcher.** Users spend <30 seconds here.
2. **Table is the core component.** Everything else is supporting.
3. **Search is essential.** Users need to find companies quickly.
4. **Quality badges are the trust layer.** Users assess data quality at a glance.
5. **Keep it minimal.** No screener, no comparison, no bulk actions.
6. **2 days of focused work.** Realistic for a senior Flutter developer.
