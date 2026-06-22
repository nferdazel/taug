# B4 — Source Attribution UX & Trust Architecture

**Date:** 2026-06-20
**Type:** Product design — no implementation
**Perspective:** Product Designer + Research Analyst + Data Platform Architect

---

## Executive Summary

TAUG's trust architecture is built on three pillars: **source**, **freshness**, and **quality**. The design philosophy is "trust through transparency" — users should always be able to verify data, but never be forced to. Trust indicators are layered: quick signals first, details on demand, full traceability available.

**Core principle:** Every number has a source. Every source has a timestamp. Every timestamp has a meaning.

---

## Trust Philosophy

### Design Principles

1. **Visible, not intrusive.** Trust signals are always present but never dominant.
2. **Understandable, not technical.** Users see "Fresh" not "last_fetched_at = 2026-06-20T05:38:08Z".
3. **Verifiable, not buried.** Full lineage is always 2 clicks away.
4. **Honest, not optimistic.** If data is stale, show it. If quality is low, show it.

### What Trust Means to the User

| Question | Answer Source |
|---|---|
| "Can I trust this number?" | Quality badge + Freshness badge |
| "Where did it come from?" | Source indicator |
| "When was it last updated?" | Freshness indicator |
| "Is it official?" | Source trust level |
| "Can I verify it?" | Lineage drill-down |

---

## Trust Model

### Three-Level Trust Hierarchy

```
Level 1: Quick Signal (always visible)
  └── Color badge + label
  └── "🟢 Fresh · 83% Quality"

Level 2: Expanded Detail (on hover/click)
  └── Source: SEC EDGAR
  └── Last reported: 2026-02-15
  └── Last fetched: 2026-06-20
  └── Quality: 83% (Coverage: 100%, Completeness: 85%)

Level 3: Full Traceability (drill-down page)
  └── Filing: 10-K, 2026-02-15
  └── Filing Version: v1, parser v0.3.0
  └── Statement: Income Statement, 2025-12-31
  └── Items: 47 line items
  └── Metric: ROE = 33.0%, formula v1
  └── Source: SEC EDGAR (sec.gov)
```

### Why Three Levels

- **Level 1** answers "can I trust this?" in 1 second
- **Level 2** answers "where did this come from?" in 5 seconds
- **Level 3** answers "can I verify this?" in 30 seconds

Most users stay at Level 1. Power users use Level 2. Auditors use Level 3.

---

## Trust Indicators

### Indicator System

| Indicator | Type | Placement | Meaning |
|---|---|---|---|
| Freshness Badge | Color badge | Company header, metric rows | How fresh is the data |
| Quality Badge | Color badge + % | Company header | Overall data reliability |
| Source Badge | Text badge | Metric detail, data page | Where data came from |
| Trust Level | Icon | Source registry | Official vs unofficial source |
| Lineage Link | Hyperlink | Metric detail | Full traceability |

### Freshness Badges

| Status | Color | Label | Threshold |
|---|---|---|---|
| Fresh | Green | Fresh | < 30 days |
| Aging | Yellow | Aging | 30-90 days |
| Stale | Red | Stale | 90-365 days |
| Expired | Gray | Expired | > 365 days |
| Unknown | Gray | — | No data |

### Quality Badges

| Score | Color | Label |
|---|---|---|
| ≥ 80% | Green | High |
| 60-80% | Yellow | Medium |
| < 60% | Red | Low |

### Source Badges

| Source | Label | Trust Level |
|---|---|---|
| SEC EDGAR | SEC | Official |
| FRED | FRED | Official |
| BPS | BPS | Official |
| Twelve Data | 12Data | Commercial |

---

## Company Workspace Trust UX

### Overview Tab

**Header area:**
```
┌─────────────────────────────────────────────────┐
│ Apple Inc. (AAPL)                               │
│ Technology · Consumer Electronics               │
│ 🟢 Fresh  🟢 83% Quality  📊 SEC               │
└─────────────────────────────────────────────────┘
```

**Key Metrics Grid:** Each metric cell shows value + subtle freshness dot
```
┌──────────┬──────────┬──────────┐
│ PE       │ PB       │ PS       │
│ 39.08 🟢 │ 41.10 🟢 │ 10.52 🟢 │
├──────────┼──────────┼──────────┤
│ ROE      │ D/E      │ FCF      │
│ 105.18%🟢│ 0.78 🟢  │ $98.8B 🟢│
└──────────┴──────────┴──────────┘
```

**Freshness dot:** 🟢 = fresh, 🟡 = aging, 🔴 = stale. Appears next to each metric value.

### Financials Tab

**Statement header:**
```
Income Statement · FY2025 · Published 2026-02-15
Source: SEC EDGAR 10-K · Last fetched: 2026-06-20
```

**Line items:** No trust indicators per line — too cluttered. Trust is at statement level.

### Valuation Tab

**Metric cards:**
```
┌─────────────────────────┐
│ PE Ratio                │
│ 39.08                   │
│ 🟢 Fresh · SEC · FY2025 │
│ [View Source]           │
└─────────────────────────┘
```

**Peer comparison:** Trust indicator on each peer's metrics.

### Research Tab

**No trust indicators.** Research is user-authored, not data-driven.

### Data Tab

**Full trust dashboard:**
```
┌─────────────────────────────────────────┐
│ Data Quality: 83% 🟢                    │
│ Freshness: 🟢 Fresh                     │
│ Sources: SEC EDGAR                      │
│                                         │
│ Coverage: 100%                          │
│ Completeness: 85%                       │
│ Validation: 50%                         │
│ Verification: 30%                       │
│                                         │
│ [View Lineage]                          │
└─────────────────────────────────────────┘
```

---

## Metric Attribution UX

### Default State (Compact)

```
ROE: 33.02%
```

No attribution visible. Clean, uncluttered.

### On Hover (Expanded)

```
ROE: 33.02%
Source: SEC EDGAR
Reported: 2026-02-15
Fetched: 2026-06-20
```

### On Click (Full Detail)

```
ROE: 33.02%
├── Source: SEC EDGAR (sec.gov)
├── Filing: 10-K, 2026-02-15
├── Filing Version: v1, parser v0.3.0
├── Statement: Income Statement, FY2025
├── Formula: net_income / stockholders_equity
├── Formula Version: v1
├── Last Reported: 2026-02-15
├── Last Fetched: 2026-06-20
└── [View Filing]
```

### Design Rationale

- **Default:** No attribution. Most users don't need it.
- **Hover:** Quick attribution. Answers "where did this come from?"
- **Click:** Full lineage. Answers "can I verify this?"

---

## Data Page Architecture

### Purpose

The Data page is the trust dashboard. It answers: "Is my data reliable?"

### Layout

```
┌──────────────────────────────────────────────────────┐
│ Data Quality                                          │
├──────────────┬───────────────┬────────────────────────┤
│ Freshness    │ Quality       │ Sources                │
│ Dashboard    │ Scores        │ Registry               │
│              │               │                        │
│ 🟢 20 Fresh  │ Apple: 83% 🟢 │ SEC EDGAR (Official)  │
│ 🟡 10 Aging  │ NVDA: 83% 🟢  │ FRED (Official)       │
│ 🔴  2 Stale  │ JPM:  25% 🔴  │ BPS (Official)        │
│ ⚪  0 Unknown│               │ 12Data (Commercial)   │
│              │               │                        │
│ [Details]    │ [Details]     │ [Details]              │
└──────────────┴───────────────┴────────────────────────┘
```

### Primary Workflows

1. **Check overall health** — glance at freshness + quality distribution
2. **Find stale companies** — identify companies needing re-sync
3. **Evaluate sources** — understand where data comes from
4. **Audit specific company** — drill into company data quality

### Success Criteria

- User can assess overall data health in 5 seconds
- User can identify stale data in 10 seconds
- User can evaluate source trustworthiness in 15 seconds

---

## Source Registry UX

### Source List View

```
┌─────────────────────────────────────────────────────┐
│ Data Sources                                         │
├──────────┬──────────┬──────────┬─────────┬──────────┤
│ Source   │ Type     │ Trust    │ Region  │ Status   │
├──────────┼──────────┼──────────┼─────────┼──────────┤
│ SEC EDGAR│ Filings  │ 🟢 Official│ US     │ Active   │
│ FRED     │ Macro    │ 🟢 Official│ US     │ Active   │
│ BPS      │ Macro    │ 🟢 Official│ ID     │ Active   │
│ Twelve   │ Price    │ 🟡 Commercial│ Global│ Active   │
└──────────┴──────────┴──────────┴─────────┴──────────┘
```

### Source Detail View

```
SEC EDGAR
├── Type: Filings
├── Trust: Official
├── Region: US
├── Organization: U.S. Securities and Exchange Commission
├── URL: sec.gov
├── Attribution Required: Yes
├── Attribution Text: "Data sourced from SEC EDGAR (sec.gov)"
├── Companies Served: 32
├── Last Sync: 2026-06-20
└── Licensing: Public domain, official government data
```

### Design Rationale

- **List view:** Quick scan of all sources
- **Detail view:** Full source evaluation
- **Trust badge:** Instant trust assessment

---

## Freshness UX

### Color System

| Status | Color | Hex | Meaning |
|---|---|---|---|
| Fresh | Green | `#10b981` | Data is current |
| Aging | Yellow | `#f59e0b` | Data is getting old |
| Stale | Red | `#f43f5e` | Data may be outdated |
| Expired | Gray | `#71717a` | Data is likely unreliable |
| Unknown | Gray | `#52525b` | No freshness data |

### Wording

- **"Fresh"** — not "Updated 2 hours ago"
- **"Aging"** — not "Updated 45 days ago"
- **"Stale"** — not "Updated 200 days ago"

**Rationale:** Users care about freshness status, not exact timestamps. Timestamps are available on hover.

### Placement

- **Company header:** Freshness badge
- **Metric rows:** Freshness dot
- **Data page:** Freshness distribution
- **Screener results:** Freshness column

---

## Data Quality UX

### Quality Score Display

```
Data Quality: 83% 🟢
```

### Quality Breakdown (on click)

```
Data Quality: 83% 🟢
├── Coverage: 100%     (how much history)
├── Completeness: 85%  (how many items)
├── Validation: 50%    (pass/fail rate)
├── Verification: 30%  (verified timestamps)
├── Freshness: 100%    (how recent)
└── Restatement: 100%  (chain integrity)
```

### Design Principles

- **Score is primary.** Users see 83%, not 6 sub-scores.
- **Breakdown is secondary.** Power users can expand.
- **No false precision.** 83% is meaningful. 83.42% is not.
- **Honest scoring.** If data is incomplete, score reflects it.

---

## Lineage UX

### When Lineage Appears

- **Metric detail view** — "View Source" link
- **Data page** — "View Lineage" link
- **Company Data tab** — Filing → Statement → Metric chain

### Lineage Chain

```
Filing: 10-K (2026-02-15)
└── Filing Version: v1 (parser v0.3.0)
    └── Statement: Income Statement (FY2025)
        └── Items: 47 line items
            └── Metric: ROE = 33.02% (formula v1)
                └── Source: SEC EDGAR
```

### Who Needs Lineage

- **Auditors** — verify data correctness
- **Power users** — understand metric derivation
- **Developers** — debug data issues

**Most users never see lineage.** It's available, not prominent.

---

## Future Readiness

### Indonesia Support

The trust architecture supports Indonesia data:
- BPS source with `Official` trust level
- BI source (future) with `Official` trust level
- IDX source (future) with `Official` trust level
- Freshness badges work for any data source
- Quality scores work for any company

### Macro Data Support

Macro data already has trust indicators:
- FRED: `Official`, `Fresh`
- BPS: `Official`, `Fresh`
- Source attribution on macro views

### Corporate Actions Support (Future)

When corporate actions are implemented:
- Lineage will show action → statement → metric chain
- Freshness will reflect restatement dates
- Quality scores will include restatement support

### Alternative Data Support (Future)

When alternative data is added:
- New source in registry with appropriate trust level
- Freshness badges work automatically
- Quality scores adapt to data type

---

## Product Risks

### Trust Fatigue

**Risk:** Users ignore trust indicators because they're always visible.

**Mitigation:** Level 1 is minimal (one badge). Users can ignore it without losing functionality.

### False Confidence

**Risk:** High quality score makes users trust incorrect data.

**Mitigation:** Quality score is honest. Low coverage = low score. Missing data = lower score.

### Over-Engineering

**Risk:** Trust system becomes too complex for users.

**Mitigation:** Three-level hierarchy. Most users stay at Level 1.

### Source Bias

**Risk:** Official sources get preferential treatment.

**Mitigation:** Trust level is informational, not functional. Commercial sources work the same way.

---

## Recommendation

1. **Implement three-level trust hierarchy.** Quick signal → expanded detail → full traceability.

2. **Start with freshness + quality badges.** These are the highest-impact trust signals.

3. **Source badges are secondary.** Most users don't care about sources until they need to verify.

4. **Lineage is tertiary.** Available for power users, hidden from casual users.

5. **Data Page is the trust dashboard.** Centralized view of data health.

6. **Desktop-first, progressive disclosure.** Trust details on hover/click, not always visible.

7. **Honest scoring.** No false precision. No false confidence.
