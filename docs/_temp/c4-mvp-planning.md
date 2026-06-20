# C4 — MVP Planning & Delivery Strategy

**Date:** 2026-06-20
**Type:** Product prioritization — no implementation
**Perspective:** Product Manager + Startup Founder + Solo Builder

---

## Executive Summary

TAUG MVP is a **Company Research Workspace** with notes and theses. That's it. One company at a time, deep research, structured thinking. Everything else is post-MVP.

**Core value proposition:** "Understand a company deeply. Record your thinking. Track your conviction."

**90-day target.** Solo developer. Part-time. Incremental releases.

---

## Core Product Loop

```
Company List → Company Workspace → Research Notes → Investment Thesis → Track Conviction
```

That's the loop. If this works, TAUG works. Everything else enhances it.

### What This Loop Requires

| Step | What | Minimum |
|---|---|---|
| Company List | Browse 32 companies | Simple table |
| Company Workspace | See financials + metrics | Overview + Financials tabs |
| Research Notes | Write notes about a company | Text editor |
| Investment Thesis | Record bull/bear case | Structured form |
| Track Conviction | Set and update conviction | Conviction selector |

---

## MVP User Journey

### Discovery

```
Open TAUG
→ See 32 companies with quality scores
→ Click a company
```

**Minimum:** Company list with name, ticker, sector, quality badge.

### Research

```
Company Workspace
→ See key metrics (PE, ROE, margins)
→ Read financial statements
→ Write a research note
```

**Minimum:** Overview tab + Financials tab + Notes.

### Decision

```
Create thesis
→ Record bull/bear case
→ Set conviction level
```

**Minimum:** Thesis form with summary, bull case, bear case, conviction.

### Tracking

```
Portfolio page
→ See positions with linked theses
→ Update conviction when thinking changes
```

**Minimum:** Position list with thesis + conviction.

### Learning

```
Close position
→ Record outcome
→ Document lessons
```

**Minimum:** Close workflow with notes.

---

## MVP Workspaces

| Workspace | MVP? | Rationale |
|---|---|---|
| Companies (list) | ✅ MUST | Entry point |
| Company Workspace | ✅ MUST | Core research |
| Research (notes + theses) | ✅ MUST | Core workflow |
| Portfolio | ✅ MUST | Tracking |
| Settings | ✅ MUST | Basic config |
| Dashboard | ❌ DEFER | Convenience, not core |
| Screener | ❌ DEFER | Discovery, not research |
| Comparison | ❌ DEFER | Decision support, not core |
| Data | ❌ DEFER | Trust, not workflow |

**MVP = 5 workspaces:** Companies, Company Workspace, Research, Portfolio, Settings.

---

## MVP Company Workspace

### Required Tabs

| Tab | MVP? | Content |
|---|---|---|
| Overview | ✅ MUST | Key metrics, summary, quality badge |
| Financials | ✅ MUST | Income statement, balance sheet, cash flow |
| Research | ✅ MUST | Notes + thesis for this company |
| Valuation | ❌ DEFER | Valuation metrics, peer comparison |
| Data | ❌ DEFER | Freshness, sources, lineage |

**MVP = 3 tabs:** Overview, Financials, Research.

### Overview Tab Content

- Company name, ticker, sector, industry
- 6 key metrics: Market Cap, PE, ROE, Gross Margin, Net Margin, D/E
- Quality badge
- Freshness badge
- Company description

### Financials Tab Content

- Income statement (annual, expandable)
- Balance sheet (annual)
- Cash flow (annual)
- Period selector (annual/quarterly)

### Research Tab Content

- List of notes for this company
- Current thesis (if any)
- Conviction badge
- "New Note" button
- "New Thesis" button

---

## MVP Research Features

| Feature | MVP? | Rationale |
|---|---|---|
| Company notes | ✅ MUST | Core research activity |
| Investment thesis | ✅ MUST | Core decision support |
| Conviction tracking | ✅ MUST | Thesis evolution |
| Research queue (watchlist) | ⚠️ SHOULD | Useful but not blocking |
| General notes | ❌ DEFER | Company-scoped is sufficient |
| Collections | ❌ DEFER | Tags are future |
| Decision journal | ❌ DEFER | Close workflow is future |

### MVP Note Features

- Create note (company-scoped)
- Edit note (plain text or simple rich text)
- Delete note
- List notes per company
- Timestamp (auto)

### MVP Thesis Features

- Create thesis (bull/bear/neutral)
- Summary field
- Bull case field
- Bear case field
- Conviction selector (low/medium/high)
- Status (active/closed)
- Linked to company

---

## MVP Comparison Features

**DEFERRED.** Comparison is a decision support tool. Users can compare manually by opening two company tabs.

**Post-MVP:** Side-by-side comparison page.

---

## MVP Portfolio Features

| Feature | MVP? | Rationale |
|---|---|---|
| Position list | ✅ MUST | Track what you own |
| Link to thesis | ✅ MUST | Why you own it |
| Conviction display | ✅ MUST | How confident |
| Entry date/price | ⚠️ SHOULD | Context |
| Close position | ⚠️ SHOULD | Lifecycle |
| P&L display | ❌ DEFER | Not primary focus |
| Alerts | ❌ DEFER | Monitoring is future |
| Sector allocation | ❌ DEFER | Analysis is future |

---

## MVP Trust Features

| Feature | MVP? | Rationale |
|---|---|---|
| Quality badge | ✅ MUST | Quick trust signal |
| Freshness badge | ✅ MUST | Data freshness |
| Source badge | ⚠️ SHOULD | Attribution |
| Quality breakdown | ❌ DEFER | Detail is future |
| Lineage | ❌ DEFER | Full traceability is future |

---

## MVP Technical Scope

### Required Dependencies

| Package | Purpose | Status |
|---|---|---|
| Flutter SDK | Framework | ✅ In use |
| go_router | Routing | ✅ In use |
| signals | State management | ✅ In use |
| supabase_flutter | Database + auth | ✅ In use |
| envied | Environment vars | ✅ In use |
| google_fonts | Typography | ✅ In use |
| intl | Formatting | ✅ In use |
| equatable | Value equality | ✅ In use |

### Optional Dependencies (MVP)

| Package | Purpose | Status |
|---|---|---|
| syncfusion_flutter_datagrid | Screener table | ⚠️ Add when screener built |
| flutter_quill | Rich text notes | ⚠️ Add when notes editor built |

### Deferred Dependencies

| Package | Purpose | When |
|---|---|---|
| syncfusion_flutter_charts | Metric charts | Post-MVP |
| url_launcher | External links | Post-MVP |

### MVP Data Layer

- Supabase client (existing)
- Repository pattern (existing)
- No new data infrastructure needed
- 32 companies already ingested
- 19 metrics already computed
- Freshness/quality already available

---

## Delivery Plan

### Phase 1: Company List + Workspace (Weeks 1-3)

| Task | Effort |
|---|---|
| Company list page | 1 day |
| Company workspace page (3 tabs) | 3 days |
| Overview tab (metrics + summary) | 2 days |
| Financials tab (statements) | 2 days |
| Research tab (notes list) | 1 day |

**Total:** ~9 days

### Phase 2: Research Workflow (Weeks 4-6)

| Task | Effort |
|---|---|
| Note editor (plain text) | 1 day |
| Note CRUD (create/edit/delete) | 1 day |
| Thesis form | 2 days |
| Conviction selector | 0.5 day |
| Research tab integration | 1 day |

**Total:** ~5.5 days

### Phase 3: Portfolio + Trust (Weeks 7-8)

| Task | Effort |
|---|---|
| Portfolio page | 2 days |
| Position tracking | 1 day |
| Quality/freshness badges | 1 day |
| Settings page | 1 day |

**Total:** ~5 days

### Phase 4: Polish + Deploy (Weeks 9-12)

| Task | Effort |
|---|---|
| Navigation polish | 1 day |
| Empty states | 1 day |
| Error handling | 1 day |
| Responsive layout | 2 days |
| Vercel deployment | 1 day |
| Testing + bug fixes | 3 days |

**Total:** ~9 days

### Total Estimate: ~29 days of focused work

With part-time availability (~3-4 hours/day), this is approximately **8-10 weeks**.

---

## Scope Traps

### Dashboard Obsession

**Trap:** "Let me build a beautiful dashboard first."

**Reality:** Dashboard is a convenience, not a workflow. Users research companies, not dashboards.

**Rule:** No dashboard until Company Workspace works perfectly.

### Screener-First Thinking

**Trap:** "Users need to discover companies. Build screener first."

**Reality:** Discovery is useful but not the core workflow. Users research specific companies.

**Rule:** Screener is post-MVP. Use existing Supabase queries for now.

### AI Features

**Trap:** "Let me add AI analysis to notes."

**Reality:** TAUG presents data, not opinions. AI is explicitly excluded.

**Rule:** No AI features until the core research workflow is solid.

### Complex Portfolio Analytics

**Trap:** "Users need P&L charts, sector allocation, risk metrics."

**Reality:** MVP portfolio is a list of positions with theses. Analytics are post-MVP.

**Rule:** Portfolio is a decision tracker, not a P&L dashboard.

### Premature Indonesia Support

**Trap:** "Let me add IDX companies for completeness."

**Reality:** Indonesia data sources (IDX, BI, OJK) are deferred. US SEC data is sufficient for MVP.

**Rule:** No Indonesia features until US workflow is proven.

### Real-time Data

**Trap:** "Users need real-time prices."

**Reality:** TAUG is for long-term investors. Daily price sync is sufficient.

**Rule:** No real-time features. Daily sync only.

### Rich Text Editor Complexity

**Trap:** "Notes need full rich text with images, tables, links."

**Reality:** Plain text notes are sufficient for MVP. Rich text is post-MVP.

**Rule:** Start with plain `TextEditingController`. Add flutter_quill later if needed.

---

## Recommendation

### MVP Definition

**TAUG MVP = Company Research Workspace + Notes + Theses + Portfolio Tracking**

### What Ships in MVP

- Company list (32 companies)
- Company workspace (Overview + Financials + Research tabs)
- Research notes (company-scoped, plain text)
- Investment theses (bull/bear/neutral + conviction)
- Portfolio (position list + linked theses)
- Trust badges (quality + freshness)
- Settings (basic)

### What Does NOT Ship in MVP

- Dashboard
- Screener
- Comparison
- Data workspace
- Rich text notes
- Charts
- Alerts
- Indonesia support
- AI features
- Real-time data

### Why This Works

1. **Core loop is complete.** Discover → Research → Decide → Track works.
2. **Solo developer scope.** ~29 days of focused work.
3. **Preserves identity.** TAUG remains a research workspace, not a terminal.
4. **Backend ready.** 32 companies, 19 metrics, freshness, quality — all exist.
5. **Incremental value.** Each phase delivers usable features.

### What Happens After MVP

- Phase 5: Screener
- Phase 6: Comparison
- Phase 7: Dashboard
- Phase 8: Rich text notes
- Phase 9: Charts
- Phase 10: Indonesia expansion
