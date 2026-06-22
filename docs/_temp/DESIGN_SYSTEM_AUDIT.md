# TAUG UI/UX Design System Audit

**Date:** 2026-06-22
**Status:** Complete

---

## Executive Summary

TAUG has a **solid foundation** but significant drift from its own design system. The codebase is ~70% compliant with its own tokens. Financial data presentation is professional but has critical gaps.

**Overall Design System Score: 6.5/10**

---

## Critical Findings (Must Fix)

### 1. Typography Scale Collapsed
**Impact:** Destroys type hierarchy
- `body`, `caption`, `micro` all render at 12px
- Spec says: 15/13/12/11/10px
- No visual differentiation between text levels

### 2. Badge Text Contrast Fails AA
**Impact:** WCAG violation
- `alpha: 0.15` backgrounds produce ~3:1 contrast
- Needs `alpha: 0.25` minimum for 4.5:1

### 3. GestureDetector Not Keyboard Accessible
**Impact:** WCAG violation
- 8 instances of `GestureDetector` on interactive elements
- Need `InkWell` + `Semantics`

### 4. Missing Semantics on Portfolio Cards
**Impact:** Screen reader inaccessible
- `_ActivePositionCard`, `_ClosedPositionCard`, `_LessonCard` — no Semantics
- `_ConvictionChip`, `_OutcomeBadge`, `_ReturnBadge` — no context

### 5. Numeric Columns Not Right-Aligned
**Impact:** Financial table convention violation
- Financial statement values need `TextAlign.right`

---

## High Priority Findings

### 6. Hardcoded Values (60+)
- `Color(0xFF27272A)` — should be `AppThemeColors.border`
- `TextStyle(fontSize: 11)` — should use `AppTypography` tokens
- `EdgeInsets.all(16)` — should use `AppSpacing.xxl`

### 7. No Onboarding Flow
- New user sees login page with no context
- No purpose statement, no workflow guide

### 8. No Success Feedback on CRUD
- Dialog closes with no confirmation
- User must verify action succeeded visually

### 9. Source Attribution Wrong
- Shows today's date instead of actual data timestamp

### 10. Duplicated Number Formatting
- 3 near-identical `_formatValue` implementations

---

## Medium Priority Findings

### 11. Dialog Width 500px (spec: 480px)
### 12. Button Height 32px (spec: 28px)
### 13. Badge Opacity Inconsistent (0.15 vs 0.25)
### 14. Section Gaps Too Large (24px vs spec 8px)
### 15. No Reduced-Motion Support
### 16. Quality Score Thresholds Inconsistent

---

## Positive Findings

| Pattern | Status |
|---|---|
| Bloomberg-terminal aesthetic | ✅ Excellent |
| Research Progression System | ✅ Excellent |
| Data Trust indicators | ✅ Excellent |
| Research Empty States | ✅ Excellent |
| Portfolio Learning Loop | ✅ Excellent |
| Shared widget Semantics | ✅ Good |
| Focus indicators (theme-level) | ✅ Present |
| Dialog keyboard behavior | ✅ Works by default |

---

## Action Plan

### Phase 1: Token Foundation (fix once, fix everywhere)
1. Fix `AppTypography` scale — restore 15/13/11/10px sizes
2. Fix `AppColors.textSecondary` — `#A1A1AA` → `#71717a`
3. Fix `AppColors.textTertiary` — `#8E8E96` → `#52525B`
4. Fix badge contrast — alpha 0.15 → 0.25

### Phase 2: Accessibility
5. Convert 8 `GestureDetector` → `InkWell` + `Semantics`
6. Add `Semantics` to portfolio cards (7 widgets)
7. Add `Semantics` to trust/metric components
8. Add `prefers-reduced-motion` support

### Phase 3: Financial Data
9. Right-align numeric columns
10. Fix source attribution
11. Centralize number formatting
12. Standardize percentage precision

### Phase 4: UX Polish
13. Add onboarding flow
14. Add success toasts for CRUD
15. Add breadcrumb navigation
16. Fix empty states

---

*Audit complete. Evidence > Opinions.*
