# C7 — Company Workspace MVP

**Date:** 2026-06-20
**Type:** Implementation plan — no code
**Perspective:** Research Product Designer + Investment Analyst + Product Engineer

---

## Executive Summary

Company Workspace is where investors understand businesses. The MVP has three tabs: **Overview** (identity + key metrics + thesis snapshot), **Financials** (statement tables), and **Research** (notes + thesis). Trust indicators are integrated into the header and overview, not in a separate tab. The workspace answers: "What is this company, how is it performing, and what do I think about it?"

---

## Workspace Purpose

### Primary Question

**"Should I invest in this company?"**

This question decomposes into:
1. What does this company do? (Overview)
2. How is the business performing? (Financials)
3. What is my current thinking? (Research)

### How It Connects

```
Companies Workspace → Company Workspace → Research → Portfolio
                          ↓
                    [Overview] [Financials] [Research]
```

---

## MVP Tabs

| Tab | MVP? | Rationale |
|---|---|---|
| Overview | ✅ MUST | Landing tab — identity, metrics, thesis snapshot |
| Financials | ✅ MUST | Core research — statement tables |
| Research | ✅ MUST | Notes + thesis — decision support |
| Valuation | ❌ DEFER | Peer comparison, historical metrics |
| Data | ❌ DEFER | Trust integrated into Overview instead |

**MVP = 3 tabs:** Overview, Financials, Research.

---

## Overview Tab

### Purpose

At-a-glance understanding of the company. Answers: "What is this company and how is it performing?"

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Overview                                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Company Summary                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ NVIDIA Corporation designs GPUs and SoCs for gaming, data   │ │
│ │ center, professional visualization, and automotive markets. │ │
│ │ [Website] [SEC Filings]                                     │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Key Metrics                                                      │
│ ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────┐ │
│ │ Market Cap│ PE       │ ROE      │ GM       │ NM       │ D/E  │ │
│ │ $5.1T    │ 42.47    │ 61.42%   │ 71.07%   │ 55.60%   │ 0.04 │ │
│ │ 🟢       │ 🟢       │ 🟢       │ 🟢       │ 🟢       │ 🟢   │ │
│ └──────────┴──────────┴──────────┴──────────┴──────────┴──────┘ │
│                                                                 │
│ My Thesis Snapshot                                               │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ NVIDIA — Bullish 🟢 High Conviction                         │ │
│ │ "AI demand drives sustained growth."                        │ │
│ │ Updated: 2026-06-15 · [View Full Thesis]                    │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Recent Filings                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ 10-Q · 2026-05-15 · 🟢 Fresh                                │ │
│ │ 10-K · 2026-02-15 · 🟢 Fresh                                │ │
│ │ 8-K  · 2026-06-01 · 🟢 Fresh                                │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Sections

| Section | Content | Priority |
|---|---|---|
| Company Summary | Description, website, SEC link | MUST |
| Key Metrics | 6 metrics with trust badges | MUST |
| Thesis Snapshot | Current thesis + conviction | MUST |
| Recent Filings | Last 3 filings | SHOULD |

---

## Thesis Snapshot

### Why It Belongs on Overview

Users open Company Workspace to make decisions. The thesis is the decision context. Without it on Overview, users must switch tabs to remember their thinking.

### What Belongs

| Field | Source | Display |
|---|---|---|
| Thesis title | `investment_theses.title` | "NVIDIA — Bullish" |
| Stance | `investment_theses.stance` | 🟢 Bullish / 🟠 Neutral / 🔴 Bearish |
| Conviction | `investment_theses.conviction` | High / Medium / Low |
| Summary | `investment_theses.summary` | First 100 characters |
| Last updated | `investment_theses.updated_at` | "Updated: 2026-06-15" |

### What Does NOT Belong

| Field | Reason |
|---|---|
| Full thesis body | Too long for Overview — belongs in Research tab |
| Bull/bear case | Detail — belongs in Research tab |
| Assumptions | Detail — belongs in Research tab |
| Exit conditions | Detail — belongs in Research tab |

### No Thesis State

```
┌─────────────────────────────────────────────────────────────────┐
│ No thesis yet                                                    │
│ [Create Thesis]                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Financials Tab

### Purpose

Deep financial statement analysis. Answers: "How is this business performing over time?"

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Financials                                        [Annual ▼]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Income Statement                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                           │ FY2025    │ FY2024    │ FY2023  │ │
│ ├───────────────────────────┼───────────┼───────────┼─────────┤ │
│ │ Revenue                   │ $130.5B   │ $60.9B    │ $26.9B  │ │
│ │ Cost of Revenue           │ $38.0B    │ $16.6B    │ $11.6B  │ │
│ │ Gross Profit              │ $92.5B    │ $44.3B    │ $15.3B  │ │
│ │ Operating Expenses        │ $11.0B    │ $7.0B     │ $5.0B   │ │
│ │ Operating Income          │ $81.5B    │ $37.3B    │ $10.3B  │ │
│ │ Net Income                │ $72.9B    │ $29.8B    │ $4.4B   │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Balance Sheet                                                    │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                           │ FY2025    │ FY2024    │ FY2023  │ │
│ ├───────────────────────────┼───────────┼───────────┼─────────┤ │
│ │ Total Assets              │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ │ Total Liabilities         │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ │ Stockholders Equity       │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ │ Cash & Equivalents        │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Cash Flow                                                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                           │ FY2025    │ FY2024    │ FY2023  │ │
│ ├───────────────────────────┼───────────┼───────────┼─────────┤ │
│ │ Operating Cash Flow       │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ │ Capital Expenditure       │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ │ Free Cash Flow            │ $X.XXB    │ $X.XXB    │ $X.XXB  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Source: SEC EDGAR · Last updated: 2026-06-20                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### MVP Statement Tables

| Table | MVP? | Rows |
|---|---|---|
| Income Statement | ✅ | Revenue, COGS, Gross Profit, OpEx, Op Income, Net Income |
| Balance Sheet | ✅ | Total Assets, Total Liabilities, Equity, Cash |
| Cash Flow | ✅ | Operating CF, CapEx, FCF |

### Deferred

| Feature | Reason |
|---|---|
| Quarterly toggle | Post-MVP — annual is sufficient |
| Statement comparison | Post-MVP — manual comparison sufficient |
| Line item expansion | Post-MVP — key items only in MVP |
| Historical charts | Post-MVP — table data is primary |

---

## Research Tab

### Purpose

Company-scoped research. Answers: "What do I think about this company?"

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Research                                     [+ Note] [+ Thesis]│
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ My Thesis                                                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ NVIDIA — Bullish 🟢 High Conviction                         │ │
│ │                                                             │ │
│ │ Summary                                                     │ │
│ │ "AI demand drives sustained growth. GPU dominance creates   │ │
│ │  pricing power. Current valuation reflects quality."        │ │
│ │                                                             │ │
│ │ Bull Case                                                   │ │
│ │ • AI capex grows 20%+                                       │ │
│ │ • GPU demand exceeds supply                                 │ │
│ │ • No competition in training                                │ │
│ │                                                             │ │
│ │ Bear Case                                                   │ │
│ │ • Competition from AMD, custom chips                        │ │
│ │ • Consumer spending slowdown                                │ │
│ │                                                             │ │
│ │ Conviction: High 🟢                                         │ │
│ │ Updated: 2026-06-15 · [Edit] [Close]                       │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ Notes (5)                                                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ 📝 Q1 2026 Earnings · 2026-05-15                            │ │
│ │    Services revenue $20.8B, +18% YoY. Strong quarter.       │ │
│ │                                                             │ │
│ │ 📝 AI Infrastructure Thesis · 2026-04-20                    │ │
│ │    GPU demand driven by AI training and inference.          │ │
│ │                                                             │ │
│ │ 📝 Competitive Analysis · 2026-03-10                        │ │
│ │    AMD MI300 gaining share but NVDA still dominant.         │ │
│ │                                                             │ │
│ │ [View All Notes]                                             │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ [No Thesis] [No Notes] — Create your first research             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Research Tab Sections

| Section | Content | Priority |
|---|---|---|
| Thesis display | Full thesis with bull/bear/assumptions | MUST |
| Notes list | Company-scoped notes | MUST |
| Create Note button | Quick note creation | MUST |
| Create Thesis button | Quick thesis creation | MUST |
| Edit/Close thesis | Thesis lifecycle | MUST |

### Research Tab vs Research Workspace

| Scope | Location | Purpose |
|---|---|---|
| Company-scoped | Company Workspace → Research tab | Notes and thesis for THIS company |
| Cross-company | Research Workspace | All notes, all theses, search |

---

## Trust Presentation

### Decision: No Separate Data Tab

Trust information is integrated into the workspace, not in a separate tab.

### Where Trust Appears

| Location | What | Component |
|---|---|---|
| Workspace header | Quality badge + Freshness badge | `QualityBadge`, `FreshnessBadge` |
| Overview tab | Key metrics with freshness dots | `MetricCard` with trust indicator |
| Financials tab | Source attribution at bottom | "Source: SEC EDGAR · Last updated: 2026-06-20" |
| Research tab | No trust indicators | User-authored content |

### Why No Data Tab

- Data tab is for deep trust inspection (lineage, sources, quality breakdown)
- MVP users don't need deep inspection — badges are sufficient
- Reduces tab count, simplifies navigation
- Data tab is post-MVP

---

## Workspace Header

### Header Component

```
┌─────────────────────────────────────────────────────────────────┐
│ NVIDIA Corp (NVDA)                                              │
│ Technology · Semiconductors · United States                     │
│ 🟢 Fresh  🟢 83% Quality                                        │
├─────────────────────────────────────────────────────────────────┤
│ Overview │ Financials │ Research                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Header Fields

| Field | Source | Display |
|---|---|---|
| Company name | `companies.display_name` | "NVIDIA Corp" |
| Ticker | `securities.ticker` | "(NVDA)" |
| Sector | `sectors.name` | "Technology" |
| Industry | `industries.name` | "Semiconductors" |
| Country | `companies.domicile_country_code` | "United States" |
| Quality badge | `data_quality_scores.overall_score` | 🟢 83% |
| Freshness badge | `company_freshness_v.statement_freshness` | 🟢 Fresh |

### Header Actions (Future)

| Action | MVP? | Purpose |
|---|---|---|
| Add to Queue | ⚠️ SHOULD | Quick research queue action |
| Compare | ❌ DEFER | Open comparison page |
| Add to Portfolio | ❌ DEFER | Quick portfolio action |

---

## Navigation Flow

### Entry Points

```
Companies Workspace → click row → Company Workspace
Research Queue → click company → Company Workspace
Portfolio → click position → Company Workspace
Screener → click result → Company Workspace (post-MVP)
```

### Internal Navigation

```
Company Workspace
├── Overview tab (default)
│   ├── Click metric → (future: metric detail)
│   ├── Click "View Full Thesis" → Research tab
│   └── Click "Create Thesis" → Research tab
├── Financials tab
│   └── Statement tables
└── Research tab
    ├── Edit thesis → thesis editor
    ├── Create note → note editor
    └── View note → note detail
```

### Exit Points

```
Company Workspace → click "Companies" tab → Companies Workspace
Company Workspace → click "Research" tab → Research Workspace
Company Workspace → browser back → previous page
```

---

## Data Requirements

### MVP Required

| Data | Source | Query |
|---|---|---|
| Company info | `companies` | `SELECT * WHERE id = ?` |
| Ticker | `securities` | `SELECT ticker WHERE company_id = ?` |
| Sector | `sectors` | `JOIN via companies.primary_sector_id` |
| Quality score | `data_quality_scores` | `SELECT overall_score WHERE company_id = ?` |
| Freshness | `company_freshness_v` | `SELECT * WHERE company_id = ?` |
| Key metrics | `company_metric_snapshot_v` | `SELECT * WHERE company_id = ?` |
| Financial statements | `company_statement_history_v` | `SELECT * WHERE company_id = ?` |
| Filings | `filings` | `SELECT * WHERE company_id = ? ORDER BY filing_date DESC` |
| Notes | `research_notes` | `SELECT * WHERE company_id = ?` |
| Thesis | `investment_theses` | `SELECT * WHERE company_id = ?` |

### Future Required

| Data | Source | When |
|---|---|---|
| Valuation metrics | `company_metric_snapshot_v` | Valuation tab |
| Line item details | `company_statement_items_v` | Statement expansion |
| Filing timeline | `filing_timeline_v` | Filing detail |

---

## Implementation Order

### Step 1: Workspace Shell (2 hours)

```
lib/features/company/
└── presentation/
    └── pages/
        └── company_workspace_page.dart
```

- Tabbed layout (3 tabs)
- Workspace header
- Empty body placeholders

### Step 2: Workspace Header (1 hour)

```
lib/features/company/
└── presentation/
    └── widgets/
        └── company_header.dart
```

- Company name + ticker
- Sector + industry
- Quality badge + Freshness badge

### Step 3: Data Layer (2 hours)

```
lib/features/company/
├── data/
│   ├── company_repository.dart
│   └── company_models.dart
└── presentation/
    └── providers/
        └── company_provider.dart
```

- Company info query
- Metrics query
- Statements query
- Notes query
- Thesis query

### Step 4: Overview Tab (3 hours)

```
lib/features/company/
└── presentation/
    ├── pages/
    │   └── company_overview_tab.dart
    └── widgets/
        ├── company_summary_card.dart
        ├── key_metrics_grid.dart
        ├── thesis_snapshot_card.dart
        └── recent_filings_list.dart
```

- Company summary card
- Key metrics grid (6 metrics)
- Thesis snapshot card
- Recent filings list

### Step 5: Financials Tab (2 hours)

```
lib/features/company/
└── presentation/
    ├── pages/
    │   └── company_financials_tab.dart
    └── widgets/
        ├── income_statement_table.dart
        ├── balance_sheet_table.dart
        └── cash_flow_table.dart
```

- Income statement table
- Balance sheet table
- Cash flow table
- Source attribution

### Step 6: Research Tab (3 hours)

```
lib/features/company/
└── presentation/
    ├── pages/
    │   └── company_research_tab.dart
    └── widgets/
        ├── thesis_display.dart
        ├── thesis_editor.dart
        ├── notes_list.dart
        └── note_editor.dart
```

- Thesis display (full view)
- Thesis editor (create/edit)
- Notes list
- Note editor (create/edit)

### Step 7: Empty States (1 hour)

- No thesis → "Create Thesis" prompt
- No notes → "Create Note" prompt
- No financials → "Data not available" message

### Step 8: Polish (1 hour)

- Loading states
- Error handling
- Keyboard navigation

### Total: ~15 hours (~3 days)

---

## Done Criteria

Company Workspace MVP is complete when:

| Criterion | Verification |
|---|---|
| Workspace renders | 3 tabs visible |
| Header shows company info | Name, ticker, sector, badges |
| Overview shows metrics | 6 key metrics with badges |
| Overview shows thesis snapshot | Current thesis + conviction |
| Financials show statements | Income, balance, cash flow tables |
| Research shows thesis | Full thesis display + edit |
| Research shows notes | Notes list + create/edit |
| Trust badges work | Quality + freshness in header |
| Empty states work | Prompts for missing data |
| Navigation works | Tab switching, back button |

After Company Workspace: Research Workspace implementation begins.

---

## Risks

### Tab Complexity

**Risk:** 3 tabs may feel too simple.

**Mitigation:** 3 tabs is correct for MVP. More tabs add complexity without value.

### Financials Table Performance

**Risk:** Statement tables with 20+ rows may be slow on Web.

**Mitigation:** Use `ListView.builder` with fixed `itemExtent`. Test early.

### Thesis Editor Complexity

**Risk:** Thesis editor with multiple sections is complex.

**Mitigation:** Start with plain text fields. Rich text is post-MVP.

### Data Loading

**Risk:** Loading metrics + statements + notes may be slow.

**Mitigation:** Parallel queries. Loading states for each section.

---

## Recommendation

1. **3 tabs is correct.** Overview, Financials, Research. No more.
2. **Thesis snapshot on Overview.** Users need decision context immediately.
3. **Trust in header, not Data tab.** Badges are sufficient for MVP.
4. **Financials are table-based.** Statement tables, not charts.
5. **Research is company-scoped.** Notes and thesis for this company only.
6. **3 days of focused work.** Realistic for a senior Flutter developer.
