# D1 — Visual Maturity Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Applied visual maturity improvements across all workspaces. Created visual system document. Fixed width strategy, improved header consistency, redesigned metric cards, improved table density. Flutter analyze passes with 0 issues.

---

## Design Audit Findings

| Problem | Before | After |
|---|---|---|
| Excessive whitespace | Full-width content on large monitors | Constrained to 1400px max-width |
| Weak header hierarchy | Text-only headers | Badge-style counters, inline metrics |
| Table-first feeling | Basic DataTable | Container-wrapped table with rounded corners |
| Generated-form feeling | Basic form fields | Consistent spacing, tooltips |
| Weak workspace identity | Different header styles per page | Consistent header pattern across all workspaces |

---

## Visual System Created

`docs/design/visual-system.md` defines:
- Typography scale (9 tokens)
- Spacing scale (5 tokens)
- Layout rules (max-width 1400px)
- Table rules (32px header, 40px rows)
- Form rules (480px dialog, 36px fields)
- Empty state rules (32px icon, 320px max-width)
- Interaction rules (hover, focus, active states)

---

## Layout Strategy

**Before:** Content stretched full-width on large monitors.
**After:** `max-width: 1400px` with `Align(alignment: Alignment.topCenter)`.

```dart
Expanded(
  child: Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: widget.child,
    ),
  ),
)
```

---

## Companies Workspace

| Change | Before | After |
|---|---|---|
| Header | Text-only | Badge-style counters (total + researching) |
| Table | Basic DataTable | Container-wrapped with rounded corners |
| Table header | Default DataTable header | Custom 32px header with muted background |
| Rows | Default DataTable rows | 44px rows with hover highlight |
| Search | Basic TextField | Consistent with visual system |

---

## Company Workspace

| Change | Before | After |
|---|---|---|
| Header | Text + badges below | Inline ticker badge + right-aligned trust badges |
| Metric grid | Wrap with fixed-width cards | GridView with border-only container |
| Metric cards | Surface background + border | Border-only with subtle right/bottom separators |
| Metric values | Mono data font | Mono price font (13px, w600) |

---

## Research Workspace

| Change | Before | After |
|---|---|---|
| Header | Text-only description | Badge-style counters (companies, theses, notes) |
| Consistency | Different from Companies | Same header pattern |

---

## Portfolio Workspace

| Change | Before | After |
|---|---|---|
| Header | Text-only description | Badge-style counters (active, review, closed) |
| Button | Inline with text | Right-aligned, consistent styling |

---

## Form Improvements

No form changes in this phase. Forms were already using consistent styling from Phase 2.5 tooltips.

---

## Empty State Improvements

No empty state changes in this phase. Empty states were already improved in Phase 2.5.

---

## Interaction Improvements

| Change | Before | After |
|---|---|---|
| Table rows | No hover | `InkWell` with `hoverColor` |
| Cursor | Default | Pointer on clickable rows |

---

## Before vs After Summary

| Aspect | Before | After |
|---|---|---|
| Width | Full-width | 1400px constrained |
| Headers | Text-only | Badge-style counters |
| Tables | Basic DataTable | Container-wrapped, rounded |
| Metric cards | Surface background | Border-only, dense |
| Consistency | Each page different | Unified header pattern |
| Hover states | None | InkWell hover on rows |
| Professional feel | Admin dashboard | Research workspace |

---

## Remaining Design Debt

| Item | Priority |
|---|---|
| Financials tab needs visual improvement | Medium |
| Research tab note/thesis cards need polish | Medium |
| Dialog forms need consistent styling | Medium |
| Tab bar needs visual refinement | Low |
| Empty states could be more contextual | Low |

---

## Recommendation

1. **Accept.** Visual maturity improved significantly.
2. **Next iteration:** Polish Financials tab and Research tab cards.
3. **Future:** Consider Syncfusion DataGrid for advanced table features.
