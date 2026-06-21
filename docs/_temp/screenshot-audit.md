# TAUG Screenshot Audit

**Created:** 2026-06-22
**Purpose:** Visual evidence of current product state.

---

## Screenshot Checklist

### Companies Workspace
- [ ] Company list with quality/freshness badges
- [ ] Search functionality
- [ ] Empty state

### Company Workspace
- [ ] Overview tab with DATA TRUST section
- [ ] Overview tab with KEY METRICS (freshness indicators)
- [ ] Financials tab with restatement indicators
- [ ] Financials tab with per-column freshness coloring
- [ ] Research tab with thesis (10 fields)
- [ ] Research tab with notes
- [ ] "Create Position" button on thesis

### Research Workspace
- [ ] "Needs Thesis" section
- [ ] Active research section
- [ ] Thesis cards with stance/conviction badges

### Portfolio Workspace
- [ ] Active positions tab
- [ ] Closed positions tab with return badges
- [ ] Lessons tab with outcome grouping
- [ ] Add Position dialog with thesis selector
- [ ] Close Position dialog with exit price

### Dialogs
- [ ] Thesis dialog (all 10 fields)
- [ ] Note dialog
- [ ] Add Position dialog (company search + thesis selector)
- [ ] Close Position dialog (outcome + exit price + lessons)
- [ ] Quality breakdown popover

### Settings
- [ ] Settings page with timezone/density options

---

## Visual Issues Found

| Issue | Severity | Location |
|---|---|---|
| textTertiary contrast too low | Medium | All section headers |
| Badge text contrast too low | Medium | Freshness/quality badges |
| No focus indicators | Medium | All interactive elements |
| Inconsistent stance badges | Low | Multiple implementations |

---

## Positive Visual Patterns

| Pattern | Evidence |
|---|---|
| Consistent card design | 1px border, no shadow, 6px radius |
| Monospace for financial data | IBM Plex Mono for numbers |
| Color-coded freshness | Green/amber/red indicators |
| Dense information layout | Bloomberg-terminal aesthetic |
| Dark theme | #09090B background |

---

## Recommendations

1. Fix textTertiary contrast (#71717A → #8E8E96)
2. Increase badge background opacity (15% → 25%)
3. Add focus indicators (accent color with alpha)
4. Deduplicate stance badges

---

*This audit should be updated with actual screenshots when available.*
