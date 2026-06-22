# C1 — Design System Architecture

**Date:** 2026-06-20
**Type:** Design system architecture — no implementation
**Perspective:** Design System Architect + Product Designer + Research Analyst

---

## Executive Summary

TAUG's design system communicates **clarity, trust, and focus**. It's built for investors who read financial data, not traders who watch flashing numbers. The system prioritizes information hierarchy over visual density, and research depth over dashboard excitement.

**Core identity:** "The Bloomberg Terminal, reimagined for individual investors — dense but readable, serious but approachable."

---

## Design Principles

### 1. Clarity Over Density

Every screen has a clear purpose. Users should know what to look at first, second, and third. Information density is high but organized — never chaotic.

### 2. Trust Over Excitement

Trust is built through consistency, transparency, and restraint. No flashy animations, no gamification, no "market is exciting" energy. Data is presented calmly and reliably.

### 3. Research Over Speculation

The design supports deep thinking, not quick reactions. Long-form content (theses, notes) gets proper space. Metrics are readable, not just visible.

### 4. Focus Over Distraction

No notifications, no pop-ups, no "trending" badges. Users come to research, not to be interrupted. The design helps users focus on what matters.

### 5. Seriousness With Approachability

The design is professional but not intimidating. Dense but not overwhelming. Serious but not cold.

---

## Information Hierarchy

### Five-Level Hierarchy

```
Level 1: Identity      — What is this? (Company name, ticker)
Level 2: Core Value    — What matters? (Key metrics, thesis status)
Level 3: Context       — What supports this? (Financials, peers, history)
Level 4: Trust         — Can I trust this? (Freshness, quality, source)
Level 5: Research      — What do I think? (Notes, conviction, comparison)
```

### Hierarchy Rules

| Rule | Application |
|---|---|
| Identity always first | Company name, ticker, sector — top of every page |
| Core value is prominent | Key metrics are large, clear, immediately visible |
| Context is accessible | Supporting data available on scroll or click |
| Trust is visible but secondary | Badges and indicators, not walls of text |
| Research is personal | User's notes and theses get dedicated space |

### Example: Company Page Hierarchy

```
Level 1: Apple Inc. (AAPL) · Technology · Consumer Electronics
Level 2: PE 39.08 · ROE 105% · Gross Margin 68%
Level 3: Income Statement · Balance Sheet · Cash Flow
Level 4: 🟢 Fresh · 🟢 83% Quality · Source: SEC EDGAR
Level 5: My Notes · My Thesis · My Conviction
```

---

## Layout System

### Grid Foundation

**Base unit:** 4px grid system

**Columns:** 12-column grid for desktop

**Breakpoints:**
- Desktop: ≥1280px (primary)
- Laptop: ≥1024px (secondary)
- Tablet: ≥768px (tertiary)
- Mobile: <768px (future)

### Content Regions

```
┌─────────────────────────────────────────────────────┐
│ Navigation Bar (40px)                                │
├────────┬────────────────────────────────────────────┤
│        │ Content Area                               │
│ Side   │ ┌─────────────────────────────────────────┐│
│ Panel  │ │ Header (identity + key metrics)          ││
│ (240px)│ ├─────────────────────────────────────────┤│
│        │ │ Tab Bar                                  ││
│        │ ├─────────────────────────────────────────┤│
│        │ │ Tab Content                              ││
│        │ │                                          ││
│        │ │                                          ││
│        │ └─────────────────────────────────────────┘│
└────────┴────────────────────────────────────────────┘
```

### Workspace Patterns

| Workspace | Layout | Rationale |
|---|---|---|
| Company | Tabbed content area | Deep research needs multiple views |
| Screener | Filter panel + results table | Discovery needs filter + browse |
| Research | Sidebar + content area | Notes need list + editor |
| Comparison | Side-by-side panels | Comparison needs parallel view |
| Portfolio | Table + detail panel | Positions need list + detail |

---

## Core Components

### Component Inventory

#### Identity Components

| Component | Purpose | Usage |
|---|---|---|
| Company Header | Company identity | Company page, screener results |
| Sector Badge | Sector classification | Company header, screener |
| Ticker Label | Stock ticker | Throughout |

#### Metric Components

| Component | Purpose | Usage |
|---|---|---|
| Metric Card | Single metric display | Dashboard, company overview |
| Metric Table | Multiple metrics | Company financials, screener |
| Metric Comparison | Side-by-side metrics | Comparison page |
| Metric Trend | Historical metric | Company valuation tab |

#### Trust Components

| Component | Purpose | Usage |
|---|---|---|
| Freshness Badge | Data freshness indicator | Company header, metrics |
| Quality Badge | Data quality indicator | Company header |
| Source Badge | Data source indicator | Metric detail, data page |
| Trust Level | Source trust indicator | Source registry |

#### Research Components

| Component | Purpose | Usage |
|---|---|---|
| Research Card | Note display | Research page, company notes |
| Thesis Card | Thesis display | Research page, company thesis |
| Conviction Badge | Conviction level | Portfolio, theses |
| Decision Card | Decision journal | Portfolio close workflow |

#### Status Components

| Component | Purpose | Usage |
|---|---|---|
| Status Badge | Generic status | Throughout |
| Alert Card | Warning/notification | Dashboard, portfolio |
| Progress Indicator | Loading state | Data fetching |

#### Navigation Components

| Component | Purpose | Usage |
|---|---|---|
| Tab Bar | Page navigation | Company workspace |
| Sidebar | Section navigation | Research, settings |
| Breadcrumb | Location context | Deep pages |

---

## Data Presentation Patterns

### Pattern Selection Guide

| Data Type | Pattern | Example |
|---|---|---|
| Single metric | Metric Card | "PE: 39.08" |
| Multiple metrics | Metric Table | Company financials |
| Comparison | Side-by-side panels | NVDA vs AMD |
| Time series | Chart + table | Historical financials |
| Research content | Card + editor | Notes, theses |
| Trust info | Badge + tooltip | Freshness, quality |
| Status | Status badge | Conviction, thesis health |

### Table Design

```
┌────────────┬──────────┬──────────┬──────────┬──────────┐
│ Company    │ PE       │ ROE      │ D/E      │ Quality  │
├────────────┼──────────┼──────────┼──────────┼──────────┤
│ Apple      │ 39.08    │ 105.18%  │ 0.78     │ 🟢 83%   │
│ NVIDIA     │ 42.47    │ 61.42%   │ 0.04     │ 🟢 83%   │
│ Microsoft  │ 28.76    │ 23.65%   │ 0.10     │ 🟢 73%   │
└────────────┴──────────┴──────────┴──────────┴──────────┘
```

**Table rules:**
- Right-align numbers
- Left-align text
- Monospace font for financial data
- Alternating row colors for readability
- Fixed header for scrolling

---

## Status System

### Status Vocabulary

| Status | Color | Word | Usage |
|---|---|---|---|
| Positive | Green | Fresh, Active, Strong | Freshness, quality, conviction |
| Warning | Yellow | Aging, Review, Building | Freshness, thesis health |
| Critical | Red | Stale, At Risk, Closed | Freshness, thesis invalidation |
| Neutral | Gray | Unknown, Pending, Archived | Default state |

### Badge Strategy

| Badge Type | Size | Placement | Example |
|---|---|---|---|
| Freshness Badge | Small (12px) | Company header, metric rows | 🟢 Fresh |
| Quality Badge | Medium (14px) | Company header | 🟢 83% |
| Conviction Badge | Medium (14px) | Portfolio, theses | 🟢 High |
| Source Badge | Small (12px) | Metric detail | SEC EDGAR |
| Sector Badge | Small (12px) | Company header | Technology |

### Indicator Hierarchy

```
Level 1: Color (green/yellow/red/gray) — instant recognition
Level 2: Word (Fresh/Aging/Stale) — clear meaning
Level 3: Number (83%, 39.08) — precise value
Level 4: Detail (on hover) — full context
```

---

## Color Philosophy

### Role-Based Colors

| Role | Color | Hex | Usage |
|---|---|---|---|
| Primary | Blue | `#3b82f6` | Links, interactive elements |
| Success | Green | `#10b981` | Positive values, fresh data, bullish |
| Warning | Yellow | `#f59e0b` | Aging data, review needed |
| Critical | Red | `#f43f5e` | Stale data, bearish, errors |
| Neutral | Gray | `#71717a` | Inactive, unknown, archived |
| Background | Dark | `#09090b` | Page background |
| Surface | Dark Gray | `#18181b` | Cards, panels |
| Border | Border Gray | `#27272a` | Separators, 1px borders |
| Text Primary | White | `#fafafa` | Main text |
| Text Secondary | Light Gray | `#a1a1aa` | Secondary text |
| Text Tertiary | Medium Gray | `#71717a` | Captions, metadata |

### Financial Colors

| Meaning | Color | Usage |
|---|---|---|
| Bullish | Green | Positive change, rising metrics |
| Bearish | Red | Negative change, declining metrics |
| Neutral | Gray | No change, flat metrics |

### Trust Colors

| Trust Level | Color | Usage |
|---|---|---|
| Official | Green | SEC, FRED, BPS |
| Commercial | Yellow | Twelve Data |
| Unverified | Gray | Unknown sources |

---

## Typography System

### Font Stack

```css
--font-sans: 'IBM Plex Sans', -apple-system, sans-serif;
--font-mono: 'IBM Plex Mono', 'Fira Code', monospace;
```

### Type Scale

| Token | Size | Weight | Usage |
|---|---|---|---|
| heading-xl | 24px | w600 | Page titles |
| heading-lg | 20px | w600 | Section titles |
| heading-md | 16px | w600 | Card titles |
| body | 14px | w400 | Primary body text |
| body-sm | 13px | w400 | Secondary body text |
| caption | 12px | w400 | Captions, metadata |
| mono-lg | 16px | w500 | Primary financial values |
| mono-md | 14px | w500 | Table data, metrics |
| mono-sm | 12px | w500 | Compact financial data |

### Typography Rules

| Rule | Application |
|---|---|
| Sans-serif for UI | Labels, navigation, descriptions |
| Monospace for data | Financial numbers, metrics, dates |
| 14px minimum body | Readability on desktop |
| 12px minimum for tables | Dense data readability |
| Right-align numbers | Tables, metric displays |
| Left-align text | Labels, descriptions |

---

## Navigation Patterns

### Primary Navigation

```
┌─────────────────────────────────────────────────────┐
│ TAUG  │ Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
└─────────────────────────────────────────────────────┘
```

**Rules:**
- Fixed at top
- Active tab highlighted
- Consistent across all pages
- Keyboard navigation supported

### Secondary Navigation (Tab Bars)

```
┌─────────────────────────────────────────────────────┐
│ Overview │ Financials │ Valuation │ Research │ Data  │
└─────────────────────────────────────────────────────┘
```

**Rules:**
- Below page header
- Context-specific tabs
- Scrollable if too many tabs
- Keyboard shortcuts (1-9)

### Navigation Behavior

| Action | Behavior |
|---|---|
| Click tab | Switch content, preserve scroll |
| Keyboard shortcut | Same as click |
| Back button | Return to previous page |
| Deep link | Navigate directly to section |

---

## Workspace Patterns

### Company Workspace

```
┌─────────────────────────────────────────────────────┐
│ Apple Inc. (AAPL) · Technology · Consumer Electronics│
│ 🟢 Fresh · 🟢 83% Quality · 📊 SEC                  │
├─────────────────────────────────────────────────────┤
│ Overview │ Financials │ Valuation │ Research │ Data  │
├─────────────────────────────────────────────────────┤
│                                                      │
│ [Tab Content Area]                                   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Screener Workspace

```
┌─────────────────────────────────────────────────────┐
│ Screener                                             │
├─────────────────┬───────────────────────────────────┤
│ Filters         │ Results                            │
│                 │                                    │
│ PE: < 20        │ Company  │ PE  │ ROE │ D/E │ Qual │
│ ROE: > 15%      │ Apple    │ 39  │ 105 │ 0.78│ 🟢   │
│ D/E: < 1.0      │ NVIDIA   │ 42  │ 61  │ 0.04│ 🟢   │
│                 │ Microsoft│ 29  │ 24  │ 0.10│ 🟢   │
│ [Apply Filters] │                                    │
│ [Save Screener] │                                    │
└─────────────────┴───────────────────────────────────┘
```

### Research Workspace

```
┌─────────────────────────────────────────────────────┐
│ Research                                             │
├─────────────────┬───────────────────────────────────┤
│ Notes List      │ Note Editor                        │
│                 │                                    │
│ 📝 AAPL Q1...   │ Apple Q1 2026 Earnings             │
│ 📝 NVDA AI...   │ Company: Apple Inc.                │
│ 📝 KO Div...    │ Tags: [earnings] [services]        │
│                 │                                    │
│ [+ New Note]    │ Services revenue $20.8B, +18%...   │
│                 │                                    │
└─────────────────┴───────────────────────────────────┘
```

---

## Empty States

### Design Philosophy

Empty states are onboarding opportunities, not dead ends.

### Empty State Patterns

| State | Message | Action |
|---|---|---|
| No Portfolio | "Start building your portfolio" | [Browse Companies] [Open Screener] |
| No Thesis | "Create your first investment thesis" | [Browse Companies] |
| No Notes | "Start researching companies" | [Browse Companies] [Open Screener] |
| No Watchlist | "Create a watchlist to track companies" | [Create Watchlist] |
| No Comparison | "Compare companies to find opportunities" | [Open Screener] |

### Empty State Design

```
┌─────────────────────────────────────────────────────┐
│                                                      │
│           📊 Start Building Your Portfolio            │
│                                                      │
│    Track your investment decisions, monitor theses,  │
│    and learn from your research.                     │
│                                                      │
│         [Browse Companies]  [Open Screener]          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Future Readiness

### Indonesia Support

The design system supports Indonesia:
- IDR currency formatting
- Indonesian language (future)
- IDX company styling
- BPS macro data presentation

### Dark Mode

The system is designed for dark mode first:
- Dark backgrounds (#09090b, #18181b)
- Light text (#fafafa)
- High contrast for financial data
- Easy on eyes for long research sessions

### Accessibility

| Requirement | Implementation |
|---|---|
| Color contrast | WCAG AA minimum |
| Keyboard navigation | All interactive elements |
| Screen reader | Semantic HTML, ARIA labels |
| Font scaling | Relative units (rem) |

### Responsive Design

| Screen | Layout | Priority |
|---|---|---|
| Desktop (≥1280px) | Full workspace | Primary |
| Laptop (≥1024px) | Reduced sidebar | Secondary |
| Tablet (≥768px) | Stacked layout | Tertiary |
| Mobile (<768px) | Simplified view | Future |

---

## Product Risks

### Over-Design

**Risk:** Design system becomes too complex for the team to maintain.

**Mitigation:** Start with essential components. Expand only when needed.

### Under-Design

**Risk:** Pages look inconsistent because the design system is too loose.

**Mitigation:** Define strict patterns for common layouts (tables, cards, badges).

### Dark Mode Lock-in

**Risk:** Dark mode makes future light mode difficult.

**Mitigation:** Use CSS variables for all colors. Light mode is a variable swap.

### Performance

**Risk:** Design system components are heavy.

**Mitigation:** Use native HTML/CSS where possible. Minimize JavaScript.

---

## Recommendation

1. **Start with core components.** Company Header, Metric Card, Trust Badge, Research Card.

2. **Define strict table patterns.** Financial tables are the most common pattern.

3. **Dark mode first.** Research platforms work better in dark mode.

4. **Typography is critical.** Monospace for data, sans-serif for UI.

5. **Status system is essential.** Freshness, quality, conviction — consistent badges everywhere.

6. **Empty states matter.** They're the first impression for new users.

7. **Keep it simple.** A design system should reduce decisions, not create them.
