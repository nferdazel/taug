# B6 — Company Comparison Architecture

**Date:** 2026-06-20
**Type:** Product design — no implementation
**Perspective:** Investor + Research Analyst + Portfolio Manager + Product Designer

---

## Executive Summary

Company comparison is a decision support workflow, not a spreadsheet exercise. TAUG's comparison architecture helps investors understand **why** companies differ, not just **how** they differ. The design prioritizes insight over data density, and integrates with the research workspace so comparison decisions become part of the user's investment journal.

**Core principle:** "Help me choose between NVDA and AMD" is a research question, not a data question.

---

## Comparison Philosophy

### What Comparison Should Achieve

Users compare companies to make decisions:
- "Should I buy NVDA or AMD?"
- "Is KO or PEP a better dividend stock?"
- "Which bank is better: JPM or BAC?"

The answer is never "they have different PE ratios." The answer is: "NVDA has higher ROIC because of AI demand, but AMD is cheaper relative to earnings growth."

### Design Principles

1. **Insight over data.** Show differences that matter, not all differences.
2. **Narrative over numbers.** Help users understand why, not just what.
3. **Decision over analysis.** Guide toward action, not just observation.
4. **Context over isolation.** Comparison should inform research, not replace it.

### What Comparison Is NOT

- A spreadsheet with 50 metrics side by side
- A ranking system
- A screener
- A replacement for individual company research

---

## Comparison Workspace

### Architecture Decision: Dedicated Page

**Recommendation:** Comparison is a **dedicated page** accessible from Company Workspace and Screener.

**Rationale:**
- Comparison is a distinct workflow (not a sub-feature of Company Workspace)
- Users compare across companies, not within one company
- Comparison results should be savable and revisitable
- Comparison page can be linked from multiple entry points

### Page Structure

```
Comparison Workspace
├── Header
│   ├── Company A selector
│   ├── Company B selector
│   └── [Swap] [Save] [Export]
├── Overview Tab
│   ├── Business Summary (side by side)
│   ├── Key Metrics Grid
│   └── Quality & Freshness
├── Financials Tab
│   ├── Income Statement Comparison
│   ├── Balance Sheet Comparison
│   └── Cash Flow Comparison
├── Valuation Tab
│   ├── Valuation Metrics
│   ├── Peer Context
│   └── Historical Comparison
├── Research Tab
│   ├── Thesis Comparison
│   ├── Conviction Comparison
│   └── Notes Comparison
└── Quality Tab
    ├── Data Quality Comparison
    ├── Freshness Comparison
    └── Source Comparison
```

### Entry Points

| Entry Point | How |
|---|---|
| Company Workspace | "Compare with..." button |
| Screener | Select 2 companies → "Compare" |
| Research Page | "Compare theses" action |
| Watchlist | Select 2 companies → "Compare" |

### Success Criteria

- User can compare two companies in 30 seconds
- User can identify the key difference in 10 seconds
- User can save comparison for future reference
- Comparison informs research workflow

---

## Comparison Dimensions

### MVP Dimensions (Must Have)

| Dimension | What It Answers | Metrics |
|---|---|---|
| Business | "What does each company do?" | Description, sector, industry |
| Valuation | "Which is cheaper?" | PE, PB, PS, EV/EBIT, EV/EBITDA |
| Profitability | "Which is more profitable?" | Gross margin, net margin, ROE, ROA |
| Growth | "Which is growing faster?" | Revenue YoY, EPS YoY |
| Balance Sheet | "Which is stronger?" | D/E, current ratio, FCF |

### Post-MVP Dimensions (Should Have)

| Dimension | What It Answers | Data |
|---|---|---|
| Quality | "Which has better data?" | Quality score, freshness |
| Research | "What do my notes say?" | Thesis comparison, conviction |
| Capital Allocation | "Which manages capital better?" | FCF margin, buybacks, dividends |

### Future Dimensions (Nice To Have)

| Dimension | What It Answers |
|---|---|
| Ownership | "Who owns these companies?" |
| Risk | "Which has more risk?" |
| ESG | "Which is more sustainable?" |
| Macro Sensitivity | "Which is more rate-sensitive?" |

---

## Side-by-Side Comparison

### Layout Strategy

```
┌──────────────────────┬──────────────────────┐
│ NVDA                 │ AMD                  │
│ NVIDIA Corp          │ Advanced Micro       │
│ Technology           │ Technology           │
│ 🟢 83% Quality       │ 🟡 72% Quality       │
├──────────────────────┼──────────────────────┤
│ Valuation            │                      │
│ PE: 42.47            │ PE: 35.20 ← cheaper  │
│ PB: 26.08            │ PB: 4.15  ← cheaper  │
│ PS: 23.61            │ PS: 8.50  ← cheaper  │
├──────────────────────┼──────────────────────┤
│ Profitability        │                      │
│ GM: 71.07% ← higher  │ GM: 50.20%           │
│ NM: 55.60% ← higher  │ NM: 22.40%           │
│ ROE: 61.42% ← higher │ ROE: 15.30%          │
├──────────────────────┼──────────────────────┤
│ Growth               │                      │
│ Rev YoY: 46.09% ←    │ Rev YoY: 12.50%      │
│ EPS YoY: N/A         │ EPS YoY: N/A         │
├──────────────────────┼──────────────────────┤
│ Balance Sheet        │                      │
│ D/E: 0.04 ← stronger │ D/E: 0.42            │
│ CR: 3.44 ← stronger  │ CR: 2.10             │
│ FCF: N/A             │ FCF: $2.1B           │
└──────────────────────┴──────────────────────┘
```

### Information Hierarchy

**Level 1: Key Differences (always visible)**
- Metrics where one company clearly outperforms the other
- Highlighted with arrows or color

**Level 2: Full Comparison (on scroll)**
- All metrics side by side
- No highlighting — raw data

**Level 3: Deep Dive (on click)**
- Historical trends for specific metric
- Source and freshness details

### Progressive Disclosure

```
Level 1: "NVDA has higher margins but AMD is cheaper"
Level 2: Full metric table
Level 3: Historical PE comparison chart
```

---

## Thesis Comparison

### Why Compare Theses

Investors don't just compare numbers. They compare **arguments**.

"NVDA bull case says AI demand sustains. AMD bull case says data center share gains. Which argument is stronger?"

### Thesis Comparison Layout

```
┌──────────────────────┬──────────────────────┐
│ NVDA Bull Thesis     │ AMD Bull Thesis      │
├──────────────────────┼──────────────────────┤
│ Summary              │ Summary              │
│ "AI demand drives    │ "Data center share   │
│  sustained growth"   │  gains accelerate"   │
├──────────────────────┼──────────────────────┤
│ Key Assumptions      │ Key Assumptions      │
│ • AI capex grows 20% │ • Market share +5%   │
│ • GPU demand > supply│ • Gross margin +3%   │
│ • No competition     │ • Intel exits GPU    │
├──────────────────────┼──────────────────────┤
│ Catalysts            │ Catalysts            │
│ • AI product cycle   │ • MI300 adoption     │
│ • Cloud expansion    │ • Console cycle      │
├──────────────────────┼──────────────────────┤
│ Risks                │ Risks                │
│ • Competition from   │ • NVDA dominance     │
│   AMD, custom chips  │ • Execution risk     │
├──────────────────────┼──────────────────────┤
│ Conviction: High 🟢  │ Conviction: Medium 🟠│
│ Valuation: Expensive │ Valuation: Fair      │
└──────────────────────┴──────────────────────┘
```

### Thesis Comparison Features

| Feature | Purpose |
|---|---|
| Assumption alignment | Show shared vs divergent assumptions |
| Risk comparison | Show which risks each thesis acknowledges |
| Conviction comparison | Show relative conviction levels |
| Valuation comparison | Show which is cheaper relative to thesis |

---

## Metric Comparison

### MVP Metrics (Must Compare)

| Metric | Category | Why Compare |
|---|---|---|
| Revenue YoY | Growth | Which is growing faster? |
| Net Margin | Profitability | Which is more profitable? |
| ROE | Profitability | Which generates better returns? |
| PE | Valuation | Which is cheaper? |
| PB | Valuation | Which is cheaper relative to book? |
| D/E | Balance Sheet | Which has stronger balance sheet? |
| FCF | Cash Flow | Which generates more cash? |
| Market Cap | Scale | Relative size context |

### Post-MVP Metrics (Should Compare)

| Metric | Category | Why Compare |
|---|---|---|
| Gross Margin | Profitability | Business quality |
| ROA | Profitability | Asset efficiency |
| PS | Valuation | Revenue-based valuation |
| EV/EBIT | Valuation | Enterprise valuation |
| Current Ratio | Liquidity | Short-term strength |
| FCF Margin | Cash Flow | Cash generation efficiency |

### Display Strategy

**Highlight differences > 20%:**
- NVDA GM: 71% ← highlighted
- AMD GM: 50%

**No highlighting for similar values:**
- NVDA CR: 3.44
- AMD CR: 2.10

**Show "N/A" gracefully:**
- NVDA FCF: N/A (negative)
- AMD FCF: $2.1B

---

## Peer Discovery

### Automatic Peer Detection

| Method | Example | How |
|---|---|---|
| Same sector | NVDA, AMD, INTC, AVGO, QCOM | `companies.sector = 'Information Technology'` |
| Same industry | NVDA, AMD | `companies.industry = 'Semiconductors'` |
| Same watchlist | User's "Tech Watchlist" | `watchlist_items` |
| Same collection | "AI Companies" | tag-based |

### Peer Suggestions

When user selects Company A for comparison:
```
Suggested Peers:
├── Same Industry: AMD, INTC, AVGO, QCOM
├── Same Sector: MSFT, AAPL, GOOGL, META
├── Same Watchlist: (user's watchlist companies)
└── [Search for company...]
```

### Peer Discovery UX

```
┌─────────────────────────────────────────────┐
│ Compare: NVDA                               │
│                                             │
│ Suggested Peers:                            │
│ ┌─────────────────────────────────────────┐ │
│ │ Industry (Semiconductors)               │ │
│ │ [AMD] [INTC] [AVGO] [QCOM]             │ │
│ ├─────────────────────────────────────────┤ │
│ │ Sector (Technology)                     │ │
│ │ [MSFT] [AAPL] [GOOGL] [META]           │ │
│ ├─────────────────────────────────────────┤ │
│ │ My Watchlist                            │ │
│ │ [AAPL] [MSFT] [AMZN]                   │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ [Search for company...]                     │
└─────────────────────────────────────────────┘
```

---

## Comparison History

### Why Retain Comparisons

Users make comparison-based decisions. Recording those decisions enables learning:
- "I chose NVDA over AMD because of higher ROIC"
- "NVDA returned +40%, AMD returned +15%"
- "My comparison logic was correct"

### Comparison Record Structure

```
Comparison: NVDA vs AMD
├── Date: 2025-06-15
├── Metrics Compared: PE, PB, ROE, GM, Rev YoY
├── Key Differences:
│   ├── NVDA: Higher margins, higher growth, expensive
│   └── AMD: Lower valuation, gaining share
├── Decision: Choose NVDA
├── Reason: "Higher ROIC, AI demand thesis stronger"
├── Outcome: (to be filled later)
│   ├── NVDA Return: +40%
│   ├── AMD Return: +15%
│   └── Verdict: Correct decision
└── Learning: "Quality premium was justified"
```

### History Features

| Feature | Purpose |
|---|---|
| Save comparison | Retain for future reference |
| Record decision | Track which company was chosen |
| Record reason | Document why |
| Record outcome | Track result |
| Review past | Learn from decisions |

---

## Research Integration

### How Comparison Enhances Research

| Integration Point | How |
|---|---|
| Notes | "Compared NVDA vs AMD. NVDA has stronger AI thesis." |
| Theses | Thesis references peer comparison |
| Watchlists | "Add both to watchlist for monitoring" |
| Conviction | Comparison strengthens/weakens conviction |

### Comparison → Research Workflow

```
1. Open Comparison: NVDA vs AMD
2. Review differences
3. Create note: "NVDA stronger on margins, AMD cheaper"
4. Update NVDA thesis: "Comparison confirms thesis"
5. Update conviction: Medium → High
6. Save comparison for reference
```

### Research → Comparison Workflow

```
1. Open NVDA thesis
2. See "Compared with: AMD" link
3. Click → Comparison page
4. Review historical comparison
5. Update thesis if needed
```

---

## Future Readiness

### Indonesia Support

Comparison works for IDX companies:
- BBCA vs BMRI
- TLKM vs EXCL
- Same framework, different market

### Multi-Company Comparison

Future: compare 3+ companies simultaneously.
```
NVDA vs AMD vs INTC
```

Layout: column-per-company with scrolling.

### Sector Comparison

Future: compare entire sectors.
```
Technology vs Healthcare
Average PE, average ROE, average growth
```

### Portfolio Comparison

Future: compare portfolio vs benchmark.
```
My Portfolio vs S&P 500
Sector allocation, quality score, freshness
```

---

## Product Risks

### Information Overload

**Risk:** Comparison page shows too many metrics.

**Mitigation:** Progressive disclosure. Level 1 shows key differences only.

### Analysis Paralysis

**Risk:** Users compare endlessly without deciding.

**Mitigation:** Comparison includes decision recording. "Which did you choose?"

### False Precision

**Risk:** Users over-interpret small metric differences.

**Mitigation:** Highlight only differences > 20%. Similar values shown without emphasis.

### Missing Context

**Risk:** Comparison without understanding business context.

**Mitigation:** Comparison starts with business description, not metrics.

---

## Recommendation

1. **Build comparison as a dedicated page.** It's a distinct workflow, not a sub-feature.

2. **Start with 2-company comparison.** Simple, focused, sufficient for MVP.

3. **Prioritize metric comparison.** Users compare numbers first, narratives second.

4. **Thesis comparison is post-MVP.** Add when theses are widely used.

5. **Comparison history is the moat.** Recording decisions enables learning.

6. **Integrate with research.** Comparison should inform notes and theses, not exist in isolation.

7. **Progressive disclosure.** Key differences first, full data on demand.
