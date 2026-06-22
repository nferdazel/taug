# C2 — Wireframe Architecture

**Date:** 2026-06-20
**Type:** Wireframe architecture — ASCII only, no implementation
**Perspective:** UX Architect + Product Designer + Research Analyst + Long-Term Investor

---

## Executive Summary

TAUG is a 7-workspace investment research platform. The wireframe architecture defines how information flows between workspaces, how navigation works, and how the complete research lifecycle appears visually. Every screen serves the core workflow: Discover → Research → Compare → Decide → Track → Learn.

**Key insight:** The Company Workspace is the center of everything. Every other workspace either leads to it or feeds from it.

---

## Global Application Layout

### Application Shell

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │                    [Page Content Area]                         │  │
│  │                                                               │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Navigation Rules

| Element | Behavior |
|---|---|
| Top nav | Fixed, always visible, 40px height |
| Page content | Scrollable, fills remaining space |
| Active tab | Highlighted with accent color |
| Tab switching | Instant, preserves scroll position |
| Keyboard | 1-7 for tab switching |

### Page Transitions

```
Dashboard ─────────────────────────────────────────────────────────
    │
    ├──→ Companies ──→ Company Workspace ──→ Comparison
    │         │              │                    │
    │         └──→ Research  └──→ Research Notes  └──→ Decision
    │
    ├──→ Screener ──→ Company Workspace
    │         │
    │         └──→ Comparison
    │
    ├──→ Research ──→ Company Workspace
    │         │
    │         └──→ Thesis ──→ Portfolio
    │
    ├──→ Portfolio ──→ Company Workspace
    │         │
    │         └──→ Decision Journal
    │
    └──→ Data ──→ Source Registry
```

---

## Companies Workspace

### Company List Page

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ 🔍 Search companies...                    [Sector ▼] [Sort ▼] │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Company        │ Sector    │ Quality │ Fresh  │ MCap     │  │  │
│  │  ├────────────────┼───────────┼─────────┼────────┼──────────┤  │  │
│  │  │ Apple Inc.     │ Tech      │ 🟢 83%  │ 🟢     │ $4.4T    │  │  │
│  │  │ NVIDIA Corp    │ Tech      │ 🟢 83%  │ 🟢     │ $5.1T    │  │  │
│  │  │ Microsoft Corp │ Tech      │ 🟢 73%  │ 🟢     │ $2.8T    │  │  │
│  │  │ Amazon.com     │ Consumer  │ 🟡 73%  │ 🟢     │ $2.6T    │  │  │
│  │  │ Alphabet Inc.  │ Tech      │ 🟡 73%  │ 🟢     │ $1.8T    │  │  │
│  │  │ ...            │           │         │        │          │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  │  Showing 32 companies                    [1] [2] [3] [Next]  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Company Search

```
┌─────────────────────────────────────────────────────────────────────┐
│ 🔍 NVDA                                                            │
├─────────────────────────────────────────────────────────────────────┤
│ NVIDIA Corp · Technology · Semiconductors                           │
│ 🟢 83% Quality · 🟢 Fresh · $5.1T Market Cap                       │
│ [View Company] [Add to Watchlist] [Compare]                         │
├─────────────────────────────────────────────────────────────────────┤
│ Search Results:                                                     │
│   NVDA · NVIDIA Corp · NASDAQ                                       │
│   NVDA.L · NVIDIA Corp (London) · LSE                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Company Workspace (Most Important Screen)

### Header

```
┌─────────────────────────────────────────────────────────────────────┐
│ NVIDIA Corp (NVDA)                                                  │
│ Technology · Semiconductors · United States                         │
│ 🟢 Fresh  🟢 83% Quality  📊 SEC EDGAR                             │
├─────────────────────────────────────────────────────────────────────┤
│ Overview │ Financials │ Valuation │ Research │ Data                 │
└─────────────────────────────────────────────────────────────────────┘
```

### Overview Tab

```
┌─────────────────────────────────────────────────────────────────────┐
│ Key Metrics                                                         │
│ ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐ │
│ │ Market Cap│ PE       │ PB       │ PS       │ ROE      │ D/E      │ │
│ │ $5.1T    │ 42.47    │ 26.08    │ 23.61    │ 61.42%   │ 0.04     │ │
│ │ 🟢       │ 🟢       │ 🟢       │ 🟢       │ 🟢       │ 🟢       │ │
│ └──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘ │
│                                                                     │
│ ┌──────────────────────────────┬──────────────────────────────────┐ │
│ │ Recent Filings               │ Data Quality                     │ │
│ │                              │                                  │ │
│ │ 10-Q · 2026-05-15 · 🟢 Fresh │ Coverage: 100%                   │ │
│ │ 10-K · 2026-02-15 · 🟢 Fresh │ Completeness: 85%               │ │
│ │ 8-K  · 2026-06-01 · 🟢 Fresh │ Validation: 50%                 │ │
│ │                              │ Freshness: 100%                  │ │
│ │ [View All Filings]           │ [View Details]                   │ │
│ └──────────────────────────────┴──────────────────────────────────┘ │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Company Summary                                                 │ │
│ │ NVIDIA Corporation designs GPUs and SoCs. The company operates  │ │
│ │ through four segments: Data Center, Gaming, Professional        │ │
│ │ Visualization, and Automotive.                                  │ │
│ │ [Website] [SEC Filings]                                         │ │
│ └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Financials Tab

```
┌─────────────────────────────────────────────────────────────────────┐
│ Income Statement · Annual · [Annual ▼] [Quarterly ▼]                │
│ Source: SEC EDGAR 10-K · Published: 2026-02-15 · 🟢 Fresh           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │                           │ FY2025    │ FY2024    │ FY2023    │ │
│ ├───────────────────────────┼───────────┼───────────┼───────────┤ │
│ │ Revenue                   │ $130.5B   │ $60.9B    │ $26.9B   │ │
│ │ Cost of Revenue           │ $38.0B    │ $16.6B    │ $11.6B   │ │
│ │ Gross Profit              │ $92.5B    │ $44.3B    │ $15.3B   │ │
│ │ Operating Expenses        │ $11.0B    │ $7.0B     │ $5.0B    │ │
│ │ Operating Income          │ $81.5B    │ $37.3B    │ $10.3B   │ │
│ │ Net Income                │ $72.9B    │ $29.8B    │ $4.4B    │ │
│ ├───────────────────────────┼───────────┼───────────┼───────────┤ │
│ │ EPS (Diluted)             │ $2.94     │ $1.21     │ $0.18    │ │
│ │ Shares Outstanding        │ 24.8B     │ 24.6B     │ 24.6B    │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ [View Balance Sheet] [View Cash Flow] [Compare]                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Valuation Tab

```
┌─────────────────────────────────────────────────────────────────────┐
│ Valuation Metrics                                                   │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Metric          │ Value  │ Status  │ Peer Avg  │ vs Peer      │ │
│ ├─────────────────┼────────┼─────────┼───────────┼──────────────┤ │
│ │ PE Ratio        │ 42.47  │ 🟢      │ 28.5      │ +48%         │ │
│ │ PB Ratio        │ 26.08  │ 🟢      │ 8.2       │ +218%        │ │
│ │ PS Ratio        │ 23.61  │ 🟢      │ 6.8       │ +247%        │ │
│ │ EV/EBIT         │ 39.07  │ 🟢      │ 22.1      │ +77%         │ │
│ │ EV/EBITDA       │ 38.23  │ 🟢      │ 18.5      │ +107%        │ │
│ └─────────────────┴────────┴─────────┴───────────┴──────────────┘ │
│                                                                     │
│ Peer Comparison: [AMD] [INTC] [AVGO] [QCOM]                        │
│ [Compare with...] [View History]                                    │
└─────────────────────────────────────────────────────────────────────┘
```

### Research Tab

```
┌─────────────────────────────────────────────────────────────────────┐
│ Research · NVIDIA Corp                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ My Thesis                                                           │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ NVIDIA — Bullish 🟢 High Conviction                             │ │
│ │ "AI demand drives sustained growth. GPU dominance creates       │ │
│ │  pricing power. Current valuation reflects quality."            │ │
│ │ Updated: 2026-06-15 · [Edit Thesis] [Close Thesis]             │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ My Notes (5)                                                        │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ 📝 Q1 2026 Earnings · 2026-05-15 · [earnings] [AI]             │ │
│ │ 📝 AI Infrastructure Thesis · 2026-04-20 · [AI] [thesis]        │ │
│ │ 📝 Competitive Analysis · 2026-03-10 · [competition]            │ │
│ │ [View All Notes] [+ New Note]                                   │ │
│ └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Tab

```
┌─────────────────────────────────────────────────────────────────────┐
│ Data Transparency · NVIDIA Corp                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ Freshness                                                           │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Filing:     🟢 Fresh · Last: 10-Q 2026-05-15                   │ │
│ │ Statement:  🟢 Fresh · Last: 2026-05-20                        │ │
│ │ Metric:     🟢 Fresh · Last: 2026-06-20                        │ │
│ │ Price:      🟢 Fresh · Last: 2026-06-20                        │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Sources                                                             │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ SEC EDGAR · Official · US                                       │ │
│ │ Organization: U.S. Securities and Exchange Commission           │ │
│ │ Attribution: Data sourced from SEC EDGAR (sec.gov)              │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ [View Full Lineage]                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Screener Workspace

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Screener                                        [Save] [Load] │  │
│  ├──────────────┬────────────────────────────────────────────────┤  │
│  │              │                                                │  │
│  │  Filters     │  Results (8 companies)                         │  │
│  │              │                                                │  │
│  │  PE    < 50  │  Company    │ PE   │ ROE    │ D/E  │ Quality   │  │
│  │  ROE   > 15% │  ──────────┼──────┼────────┼──────┼─────────  │  │
│  │  D/E   < 1.0 │  Adobe      │ 10.88│ 61.90% │ 0.42 │ 🟢 83%   │  │
│  │  GM    > 30% │  JNJ        │ 20.51│ 33.02% │ 0.46 │ 🟢 83%   │  │
│  │              │  Honeywell  │ 30.69│ 34.80% │ 2.36 │ 🟢 82%   │  │
│  │  [Add Filter]│  Salesforce │ 16.67│ 21.78% │ 1.15 │ 🟢 83%   │  │
│  │  [Clear All] │  Visa       │ N/A  │ N/A    │ N/A  │ 🟡 76%   │  │
│  │              │  Intel      │ N/A  │ -0.24% │ 0.39 │ 🟢 83%   │  │
│  │  Universe:   │  Costco     │ 67.75│ 18.59% │ 0.17 │ 🟢 83%   │  │
│  │  [All ▼]     │  Linde      │ 34.35│ 17.89% │ 0.56 │ 🟢 83%   │  │
│  │              │                                                │  │
│  │  Sort:       │  [Compare Selected] [Add to Watchlist]          │  │
│  │  [ROE ▼]     │                                                │  │
│  │              │                                                │  │
│  └──────────────┴────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Research Workspace

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Research                                    [+ Note] [+ Thesis]│  │
│  ├──────────────┬────────────────────────────────────────────────┤  │
│  │              │                                                │  │
│  │  Notes (12)  │  📝 Apple Q1 2026 Earnings                     │  │
│  │              │  Company: Apple Inc. (AAPL)                    │  │
│  │  📝 AAPL Q1..│  Tags: [earnings] [services] [AI]             │  │
│  │  📝 NVDA AI..│  Created: 2026-01-30                          │  │
│  │  📝 KO Div.. │                                                │  │
│  │  📝 XOM Oil..│  Services revenue $20.8B, +18% YoY.           │  │
│  │              │  iPhone revenue $69.7B, +2% YoY.               │  │
│  │  Theses (5)  │  Gross margin 46.9%. Strong quarter.           │  │
│  │              │                                                │  │
│  │  🟢 AAPL     │  Key takeaway: Services growth thesis          │  │
│  │  🟢 NVDA     │  validated. Ecosystem durability confirmed.    │  │
│  │  🟠 KO       │                                                │  │
│  │  🟠 XOM      │  [Edit] [Delete] [Link to Thesis]              │  │
│  │  🟡 JPM      │                                                │  │
│  │              │                                                │  │
│  │  Tags        │                                                │  │
│  │  [earnings]  │                                                │  │
│  │  [AI]        │                                                │  │
│  │  [dividend]  │                                                │  │
│  │  [valuation] │                                                │  │
│  │              │                                                │  │
│  └──────────────┴────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Comparison Workspace

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Compare: [NVIDIA ▼] vs [AMD ▼]              [Swap] [Save]    │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  ┌─────────────────────┬─────────────────────┐                │  │
│  │  │ NVIDIA Corp (NVDA)  │ AMD (AMD)           │                │  │
│  │  │ Technology          │ Technology           │                │  │
│  │  │ 🟢 83% Quality      │ 🟡 72% Quality      │                │  │
│  │  ├─────────────────────┼─────────────────────┤                │  │
│  │  │ Valuation           │                     │                │  │
│  │  │ PE: 42.47           │ PE: 35.20 ← cheaper │                │  │
│  │  │ PB: 26.08           │ PB: 4.15  ← cheaper │                │  │
│  │  │ PS: 23.61           │ PS: 8.50  ← cheaper │                │  │
│  │  ├─────────────────────┼─────────────────────┤                │  │
│  │  │ Profitability       │                     │                │  │
│  │  │ GM: 71.07% ← higher │ GM: 50.20%          │                │  │
│  │  │ NM: 55.60% ← higher │ NM: 22.40%          │                │  │
│  │  │ ROE: 61.42% ← higher│ ROE: 15.30%         │                │  │
│  │  ├─────────────────────┼─────────────────────┤                │  │
│  │  │ Balance Sheet       │                     │                │  │
│  │  │ D/E: 0.04 ←stronger │ D/E: 0.42           │                │  │
│  │  │ CR: 3.44 ←stronger  │ CR: 2.10            │                │  │
│  │  └─────────────────────┴─────────────────────┘                │  │
│  │                                                               │  │
│  │  [View Thesis Comparison] [Save Decision] [Add to Research]   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Portfolio Workspace

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Portfolio                               [+ Position] [Closed] │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  Summary                                                       │  │
│  │  ┌──────────┬──────────┬──────────┬──────────┐                │  │
│  │  │ Positions│ Convic.  │ Sectors  │ Fresh    │                │  │
│  │  │ 5 active │ 3H · 2M  │ 4        │ 4F · 1A  │                │  │
│  │  └──────────┴──────────┴──────────┴──────────┘                │  │
│  │                                                               │  │
│  │  Positions                                                     │  │
│  │  ┌────────┬────────┬────────┬────────┬────────┬────────────┐  │  │
│  │  │ Company│ Sector │ Thesis │ Convic │ Entry  │ Status     │  │  │
│  │  ├────────┼────────┼────────┼────────┼────────┼────────────┤  │  │
│  │  │ NVDA   │ Tech   │ Bull 🟢│ High   │ $450   │ 🟢 Fresh   │  │  │
│  │  │ AAPL   │ Tech   │ Bull 🟢│ High   │ $150   │ 🟢 Fresh   │  │  │
│  │  │ KO     │ Staples│ Bull 🟠│ Medium │ $55    │ 🟢 Fresh   │  │  │
│  │  │ XOM    │ Energy │ Bull 🟠│ Medium │ $95    │ 🟢 Fresh   │  │  │
│  │  │ JPM    │ Fin    │ Neut 🟡│ Low    │ $180   │ 🟡 Aging   │  │  │
│  │  └────────┴────────┴────────┴────────┴────────┴────────────┘  │  │
│  │                                                               │  │
│  │  Alerts                                                        │  │
│  │  🟡 JPM: Filing data stale (>90 days)                         │  │
│  │  🟢 NVDA: New 10-Q available                                  │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Workspace

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Data Quality & Trust                                           │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  Freshness Dashboard                                           │  │
│  │  ┌──────────┬──────────┬──────────┬──────────┐                │  │
│  │  │ 🟢 Fresh │ 🟡 Aging │ 🔴 Stale │ ⚪ Unknown│                │  │
│  │  │ 20       │ 10       │ 2        │ 0        │                │  │
│  │  └──────────┴──────────┴──────────┴──────────┘                │  │
│  │                                                               │  │
│  │  Quality Scores                                                │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ Apple Inc.        │ 🟢 83% │ Coverage: 100% │ Fresh: 100%│ │  │
│  │  │ NVIDIA Corp       │ 🟢 83% │ Coverage: 100% │ Fresh: 100%│ │  │
│  │  │ Microsoft Corp    │ 🟡 73% │ Coverage: 60%  │ Fresh: 100%│ │  │
│  │  │ JPMorgan Chase    │ 🔴 25% │ Coverage: 0%   │ Fresh: N/A │ │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  │  Sources                                                       │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ SEC EDGAR  │ 🟢 Official │ US  │ 32 companies            │  │  │
│  │  │ FRED       │ 🟢 Official │ US  │ 5 macro series          │  │  │
│  │  │ BPS        │ 🟢 Official │ ID  │ 4 macro series          │  │  │
│  │  │ Twelve Data│ 🟡 Commercial│ Global│ 32 price snapshots   │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Dashboard Strategy

### Decision: Dashboard Exists (Lightweight)

Dashboard is a **launchpad**, not a monitoring screen.

```
┌─────────────────────────────────────────────────────────────────────┐
│ TAUG    Dashboard │ Companies │ Screener │ Research │ Portfolio │ Data │ Settings │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Dashboard                                                      │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  Data Health                                                   │  │
│  │  ┌──────────┬──────────┬──────────┐                           │  │
│  │  │ 🟢 Fresh │ 🟡 Aging │ 🔴 Stale │                           │  │
│  │  │ 20       │ 10       │ 2        │                           │  │
│  │  └──────────┴──────────┴──────────┘                           │  │
│  │                                                               │  │
│  │  Recent Research                                               │  │
│  │  📝 Apple Q1 Earnings · 2 hours ago                           │  │
│  │  📝 NVDA AI Thesis · 1 day ago                                │  │
│  │  📊 NVDA vs AMD Comparison · 2 days ago                       │  │
│  │                                                               │  │
│  │  Active Theses                                                 │  │
│  │  🟢 NVDA · High Conviction · Updated 2 days ago               │  │
│  │  🟢 AAPL · High Conviction · Updated 1 week ago               │  │
│  │  🟠 KO · Medium Conviction · Updated 2 weeks ago              │  │
│  │                                                               │  │
│  │  Quick Actions                                                 │  │
│  │  [Open Screener] [New Note] [Browse Companies]                │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Mobile Adaptation Strategy

### What Collapses

| Element | Desktop | Mobile |
|---|---|---|
| Navigation | 7 tabs | Bottom nav (5 tabs) + overflow |
| Company Workspace | 5 tabs | Accordion sections |
| Screener | Side-by-side | Stacked (filters → results) |
| Comparison | Side-by-side | Stacked (scroll) |
| Tables | Full columns | Key columns only |

### What Remains

| Element | Desktop | Mobile |
|---|---|---|
| Company Header | Full | Compact |
| Trust Badges | Full | Compact |
| Key Metrics | Grid | List |
| Research Notes | Full | Full |

### What Disappears (Mobile)

| Element | Rationale |
|---|---|
| Data Workspace | Too complex for mobile |
| Full comparison | Too dense |
| Advanced filters | Too complex |

---

## Workflow Validation

### Complete Workflow Path

```
1. DISCOVER
   Screener → Apply filters → Find NVDA
   
2. RESEARCH
   NVDA Company Workspace → Read financials → Create note → Create thesis
   
3. COMPARE
   NVDA vs AMD → Side-by-side metrics → Thesis comparison
   
4. DECIDE
   Set conviction: High → Add to Portfolio
   
5. TRACK
   Portfolio → Monitor thesis → Update conviction → Review alerts
   
6. LEARN
   Close position → Record outcome → Document lessons
```

### Navigation Friction Points

| Transition | Friction | Solution |
|---|---|---|
| Screener → Company | 1 click | ✅ Low friction |
| Company → Comparison | 2 clicks | ⚠️ Add "Compare" button |
| Research → Portfolio | 2 clicks | ⚠️ Add "Add to Portfolio" in thesis |
| Portfolio → Company | 1 click | ✅ Low friction |

---

## MVP Scope

### Must Have (MVP)

| Screen | Rationale |
|---|---|
| Company Workspace (Overview + Financials) | Core research workflow |
| Screener (filters + results) | Discovery |
| Research (notes + theses) | User workflow |
| Portfolio (positions + watchlists) | Tracking |
| Settings (basic) | Configuration |

### Should Have (Post-MVP)

| Screen | Rationale |
|---|---|
| Dashboard | Convenience |
| Company Valuation Tab | Depth |
| Company Data Tab | Trust |
| Comparison Page | Decision support |
| Data Workspace | Transparency |

### Future

| Screen | Rationale |
|---|---|
| Mobile adaptation | Reach |
| Advanced comparison | Depth |
| Portfolio analytics | Insights |
| Macro dashboard | Context |

---

## Product Risks

### Information Overload

**Risk:** Too many screens, too much data.

**Mitigation:** Progressive disclosure. Overview first, details on demand.

### Navigation Confusion

**Risk:** Users get lost between workspaces.

**Mitigation:** Consistent navigation. Company Workspace is always reachable.

### Empty States

**Risk:** New users have nothing to see.

**Mitigation:** Onboarding flow. Example data. Screener as discovery tool.

### Feature Creep

**Risk:** Every screen gets more features.

**Mitigation:** MVP scope is ruthless. Features must serve the workflow.

---

## Recommendation

1. **Company Workspace is the center.** Every other workspace leads to or from it.

2. **Screener is the discovery engine.** Users find companies through screener.

3. **Research is the workflow.** Notes and theses are how users build conviction.

4. **Portfolio is the tracker.** Positions with linked theses.

5. **Dashboard is minimal.** Health + recent activity + quick access.

6. **Desktop-first.** Mobile is a future adaptation, not a primary target.

7. **Start with 5 screens.** Company, Screener, Research, Portfolio, Settings.
