# B3 — UI Architecture & Product Design

**Date:** 2026-06-20
**Type:** Product architecture — no implementation
**Perspective:** Product Manager + UX Architect + Investment Research User

---

## Executive Summary

TAUG is an investment research workspace for long-term equity investors. The platform prioritizes depth over breadth, trust over speed, and research workflow over real-time monitoring. The design is company-centric, data-transparent, and workflow-oriented.

**Core insight:** The user doesn't need another stock ticker. They need a place to understand companies, build conviction, and track their research over time.

---

## Product Vision

### What TAUG Is

- **Investment workspace** — a place where research happens, not just where data is displayed
- **Research platform** — depth-first, company-centric, evidence-based
- **Decision support tool** — helps users build and validate investment theses

### What TAUG Is NOT

- Stock ticker app
- News feed
- Social network
- Trading platform
- AI advisor

### Design Mantras

1. **"Show me the data, then let me think."** — TAUG presents evidence, not opinions.
2. **"Every number has a source."** — Trust is built through transparency.
3. **"My research, my workspace."** — Users build their own research environment.
4. **"Depth over breadth."** — Better to deeply understand 30 companies than superficially track 3,000.

---

## User Workflow

### Primary User: Long-Term Equity Investor

**Goals:**
- Understand companies deeply
- Compare companies across sectors
- Build and maintain watchlists
- Develop investment theses
- Discover undervalued opportunities
- Validate assumptions with data

**Typical Session:**

```
Open TAUG
  → Check dashboard for freshness/quality alerts
  → Navigate to Company Workspace
    → Review latest financials
    → Check valuation metrics
    → Read research notes
    → Update thesis
  → Navigate to Screener
    → Apply filters (PE < 20, ROE > 15%)
    → Save screener
    → Drill into result
  → Navigate to Research
    → Review watchlist
    → Add notes
    → Compare companies
```

### Secondary Workflows

**Discovery:** Screener → Company → Research
**Validation:** Company → Financials → Sources → Freshness
**Monitoring:** Dashboard → Alerts → Company → Notes

---

## Navigation Architecture

### Recommended: 7-Tab Navigation

```
┌─────────────────────────────────────────────────────┐
│ TAUG  │ Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
└─────────────────────────────────────────────────────┘
```

| Tab | Purpose | Priority |
|---|---|---|
| Dashboard | Freshness alerts, quality overview, quick access | Must Have |
| Companies | Company search, browse, company workspace | Must Have |
| Screener | Filter, sort, discover companies | Must Have |
| Research | Notes, theses, watchlists, collections | Must Have |
| Portfolio | Holdings, P&L, allocation | Should Have |
| Data | Data quality, freshness, sources | Should Have |
| Settings | Preferences, home market, display | Must Have |

### Why These Tabs

**Dashboard** — Gives users a "home base" that shows data health and quick access to recent research.

**Companies** — The primary entry point. Users research specific companies. This tab leads to the Company Workspace.

**Screener** — Discovery tool. Users find companies they didn't know they wanted to research.

**Research** — The workspace. Notes, theses, watchlists. This is where research happens over time.

**Portfolio** — Tracks what the user owns. Less important than research for long-term investors.

**Data** — Transparency layer. Shows freshness, quality, sources. Builds trust.

**Settings** — Configuration. Home market, display preferences.

### What Was Removed

- **Brief** — Terminal-style landing page. Not needed for research workflow.
- **Market** — Real-time movers. Not aligned with long-term investor persona.
- **Chart** — Standalone charting. Company Workspace includes relevant charts.
- **News** — Context feed. Can be added later as a Data sub-feature.
- **Policy** — Context feed. Can be added later.
- **Calendar** — Context feed. Can be added later.

**Rationale:** The original 12-tab layout was designed for a terminal monitor. The research platform needs fewer, deeper pages.

---

## Page Architecture

### Dashboard

**Purpose:** Home base. Shows data health, recent activity, quick access.

**Primary Actions:**
- Navigate to recently researched companies
- See data freshness alerts
- See quality score changes

**Secondary Actions:**
- Navigate to screener
- Navigate to research notes

**Displayed Information:**
- Data freshness overview (how many companies are fresh/aging/stale)
- Quality score distribution
- Recent research activity (last viewed companies)
- Quick links to saved screeners

**Success Criteria:** User can assess data health in 5 seconds. User can navigate to any company in 2 clicks.

---

### Companies Page

**Purpose:** Browse and search companies. Entry point to Company Workspace.

**Primary Actions:**
- Search companies by name/ticker
- Filter by sector, quality score, freshness
- Navigate to Company Workspace

**Secondary Actions:**
- Add company to watchlist
- Compare companies

**Displayed Information:**
- Company list with: name, ticker, sector, quality score, freshness badge
- Sector distribution
- Sort by: name, market cap, quality, freshness

**Success Criteria:** User can find any company in 3 seconds. User can assess company quality at a glance.

---

### Company Workspace (see detailed section below)

---

### Screener Page

**Purpose:** Discover companies by filtering on financial metrics.

**Primary Actions:**
- Apply metric filters (PE < 20, ROE > 15%)
- Sort results
- Save screener
- Drill into company

**Secondary Actions:**
- Load saved screener
- Export results
- Compare results

**Displayed Information:**
- Filter panel (left)
- Results table (center)
- Saved screeners (sidebar)

**Success Criteria:** User can find undervalued companies in 30 seconds. User can save and reload screeners.

---

### Research Page

**Purpose:** Manage research notes, theses, and collections.

**Primary Actions:**
- Create/edit research notes
- Create/edit investment theses
- Manage watchlists
- Browse research by company or tag

**Secondary Actions:**
- Search notes
- Export research
- Link notes to companies

**Displayed Information:**
- Notes list
- Thesis cards
- Watchlist view
- Tag cloud

**Success Criteria:** User can find any research note in 5 seconds. User can build a thesis over time.

---

### Portfolio Page

**Purpose:** Track holdings and P&L.

**Primary Actions:**
- View holdings
- See P&L
- See allocation

**Secondary Actions:**
- Add/remove holdings
- Link holdings to research notes

**Displayed Information:**
- Holdings table with: ticker, quantity, avg price, current price, P&L
- Sector allocation
- Total value

**Success Criteria:** User knows their portfolio status at a glance.

---

### Data Page

**Purpose:** Transparency layer. Shows data quality, freshness, sources.

**Primary Actions:**
- View freshness dashboard
- View quality scores
- View source registry

**Secondary Actions:**
- Filter by quality/freshness
- See data lineage

**Displayed Information:**
- Freshness overview (per company)
- Quality score distribution
- Source list with attribution
- Macro data status

**Success Criteria:** User trusts the data. User can identify stale data.

---

### Settings Page

**Purpose:** Configuration.

**Primary Actions:**
- Set home market
- Set preferred exchanges
- Set base currency
- Set display preferences

**Displayed Information:**
- Preference form
- Account info

**Success Criteria:** User can configure their research context in 1 minute.

---

## Company Workspace (Detailed)

This is the most important page. It's where deep research happens.

### Recommended Structure

```
Company Workspace
├── Header (name, ticker, sector, quality badge, freshness badge)
├── Overview Tab
│   ├── Company Summary
│   ├── Key Metrics Grid
│   ├── Recent Filings
│   └── Data Quality Summary
├── Financials Tab
│   ├── Income Statement
│   ├── Balance Sheet
│   ├── Cash Flow
│   └── Statement Comparison
├── Valuation Tab
│   ├── Valuation Metrics
│   ├── Peer Comparison
│   └── Historical Valuation
├── Research Tab
│   ├── Notes
│   ├── Thesis
│   └── Tags
└── Data Tab
    ├── Freshness
    ├── Sources
    └── Lineage
```

### Tab Details

#### Overview Tab

**Purpose:** At-a-glance company understanding.

**Sections:**

1. **Company Summary** — Name, ticker, sector, industry, description, website
2. **Key Metrics Grid** — 6-8 most important metrics in a compact grid:
   - Market Cap, PE, PB, PS
   - ROE, ROA, Gross Margin, Net Margin
   - D/E, FCF, Revenue YoY, EPS YoY
3. **Recent Filings** — Last 5 filings with type, date, link
4. **Data Quality Summary** — Quality score, freshness badges, source count

**Design Principle:** "If I only see this tab, do I understand the company?" Yes.

#### Financials Tab

**Purpose:** Deep financial statement analysis.

**Sections:**

1. **Income Statement** — Annual + quarterly, expandable rows
2. **Balance Sheet** — Annual + quarterly
3. **Cash Flow** — Annual + quarterly
4. **Statement Comparison** — Side-by-side period comparison

**Design Principle:** "Show me the raw numbers. Let me do my own analysis."

#### Valuation Tab

**Purpose:** Valuation context.

**Sections:**

1. **Valuation Metrics** — PE, PB, PS, EV/EBIT, EV/EBITDA with historical context
2. **Peer Comparison** — Same metrics for sector peers
3. **Historical Valuation** — Metric trends over time

**Design Principle:** "Is this company cheap or expensive relative to itself and its peers?"

#### Research Tab

**Purpose:** User's own research.

**Sections:**

1. **Notes** — User's research notes for this company
2. **Thesis** — User's investment thesis (bull/bear/neutral)
3. **Tags** — User-defined tags

**Design Principle:** "This is my research space. I write, I think, I build conviction."

#### Data Tab

**Purpose:** Data transparency.

**Sections:**

1. **Freshness** — When each data dimension was last updated
2. **Sources** — Where the data came from
3. **Lineage** — Filing → Statement → Metric chain

**Design Principle:** "Every number has a source. I can verify it."

---

## Screener Workflow

### User Journey: Find Undervalued Companies

```
1. Open Screener
2. Select universe (default: all, or by sector)
3. Add filters:
   - PE < 20
   - ROE > 15%
   - Debt/Equity < 1.0
   - Gross Margin > 30%
4. Sort by: PE ascending
5. View results table
6. Click company → Company Workspace
7. Save screener: "Undervalued Quality"
8. Return later: Load "Undervalued Quality"
```

### Filter Design

**Operators:** <, >, <=, >=, =, between, is null, is not null

**Metrics available:** All 19 computed metrics

**Null policy:** Exclude (default), Include, Warn

**Universe:** All companies, or by sector

### Saved Screeners

**Stored:** Filter definition, sort definition, universe, name, description

**Access:** Research Page → Saved Screeners, or Screener sidebar

**Sharing:** Future feature (not MVP)

### Result Table

**Columns:** Company, Ticker, Sector, Quality, Freshness, + selected metrics

**Sort:** Any column, ascending/descending

**Drill-down:** Click row → Company Workspace

---

## Research Workspace

### Notes

- **Scoped to company** — each note belongs to a company
- **Free-form text** — user writes what they want
- **Timestamped** — created_at, updated_at
- **Searchable** — full-text search

### Theses

- **Scoped to company** — each thesis belongs to a company
- **Stance:** Bullish, Bearish, Neutral
- **Summary:** One-paragraph thesis statement
- **Status:** Active, Closed, Revisiting
- **Linked to notes** — thesis references research notes

### Watchlists

- **Named collections** — "Tech Watchlist", "Value Plays"
- **Company references** — each item is a company
- **Sortable** — by any metric
- **Freshness-aware** — shows data freshness per company

### Collections (Future)

- **Tag-based grouping** — "AI Companies", "Dividend Aristocrats"
- **Cross-company analysis** — compare companies by tag

---

## Data Trust UX

### Freshness Display

**Company level:** Badge showing latest freshness status
- 🟢 Fresh (< 30 days)
- 🟡 Aging (30-90 days)
- 🔴 Stale (> 90 days)
- ⚪ Unknown

**Metric level:** "Last calculated: 2026-06-20"

**Price level:** "Last price: $298.01 (2026-06-20)"

### Quality Display

**Company level:** Quality score badge (0-100%)
- 🟢 ≥ 80%
- 🟡 60-80%
- 🔴 < 60%

**Component level:** Expandable breakdown (coverage, completeness, validation, freshness)

### Source Attribution

**Company level:** "Data from SEC EDGAR"

**Metric level:** "Source: SEC EDGAR filing 2026-02-15"

**Macro level:** "Source: FRED (Federal Reserve Economic Data)"

**Design Principle:** "Trust is built through transparency, not through hiding complexity."

---

## Dashboard Strategy

### Should Dashboard Exist?

**Yes.** But it should be lightweight, not a "dashboard syndrome" trap.

### What Belongs on Dashboard

1. **Data Health** — Freshness overview, quality distribution
2. **Recent Activity** — Last 5 viewed companies
3. **Quick Access** — Saved screeners, watchlists
4. **Alerts** — Quality drops, freshness warnings

### What Does NOT Belong on Dashboard

- Real-time prices
- News feed
- Market movers
- Charts
- Social features

**Rationale:** Dashboard is a launchpad for research, not a monitoring screen.

---

## MVP Scope

### Must Have (MVP)

| Feature | Rationale |
|---|---|
| Company Workspace (Overview + Financials) | Core research workflow |
| Screener (filters + sort + save) | Discovery |
| Research Notes | User workflow |
| Watchlists | Organization |
| Data Trust (freshness + quality badges) | Trust |
| Settings (home market, currency) | Configuration |

### Should Have (Post-MVP)

| Feature | Rationale |
|---|---|
| Dashboard | Convenience |
| Valuation Tab | Depth |
| Portfolio Tracking | Ownership |
| Data Page | Transparency |
| Research Theses | Workflow |
| Peer Comparison | Analysis |

### Nice To Have

| Feature | Rationale |
|---|---|
| Historical metric charts | Visualization |
| Export (CSV/PDF) | Utility |
| Multi-currency display | International |
| Company relationships | Research depth |

### Future

| Feature | Rationale |
|---|---|
| Indonesia companies | Expansion |
| Macro dashboard | Context |
| News integration | Awareness |
| Collaboration | Team research |
| AI features | Enhancement |

---

## Mobile vs Desktop

### Decision: Desktop-First

**Rationale:**

1. **Primary use case is research.** Research requires screen space, multiple panels, detailed data tables. Mobile is wrong form factor.

2. **User persona is long-term investor.** They research at a desk, not on a train.

3. **Data density.** Financial tables need horizontal space. Mobile would require severe data reduction.

4. **Competitive landscape.** Bloomberg, FactSet, Refinitiv are all desktop-first. Research tools are desktop tools.

### Mobile Strategy

**Responsive, not mobile-first.** The app should work on tablets for casual browsing, but primary experience is desktop.

**Mobile use cases (future):**
- Check portfolio on phone
- Read research notes
- Quick screener check
- Alerts/notifications

**Not mobile use cases:**
- Deep financial analysis
- Multi-company comparison
- Research note writing
- Screener building

---

## Product Risks

### Information Overload

**Risk:** Too many metrics, too much data, user overwhelmed.

**Mitigation:** Progressive disclosure. Overview tab shows key metrics. Financials tab shows everything. User chooses depth.

### Dashboard Syndrome

**Risk:** Dashboard becomes a monitoring screen instead of a research launchpad.

**Mitigation:** Dashboard is minimal. No real-time data. No news feed. Just health + access.

### Feature Bloat

**Risk:** Every feature gets added. Platform becomes unwieldy.

**Mitigation:** MVP scope is ruthless. Features must serve the research workflow or they're deferred.

### AI Feature Temptation

**Risk:** "Let's add AI analysis." Platform becomes opinionated instead of evidence-based.

**Mitigation:** AI is explicitly excluded. TAUG presents data, not opinions.

### Research Fragmentation

**Risk:** Research notes scattered across companies. No unified view.

**Mitigation:** Research Page aggregates all notes, theses, watchlists. User can search across everything.

---

## Recommendation

1. **Start with Company Workspace.** This is the core product. If the Company Workspace works, everything else follows.

2. **Build Screener second.** Discovery is the second most important workflow.

3. **Build Research Page third.** Research workflow is the long-term moat.

4. **Dashboard is last.** It's a convenience, not a core workflow.

5. **Desktop-first, responsive.** Don't compromise the research experience for mobile.

6. **Progressive disclosure.** Show key metrics first, details on demand.

7. **Trust through transparency.** Freshness, quality, sources — always visible, never hidden.
