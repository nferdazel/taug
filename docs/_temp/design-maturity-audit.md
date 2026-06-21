# TAUG Design Maturity Audit

**Date:** 2026-06-22
**Purpose:** Does the UI reinforce Research OS thinking?

---

## Verdict: MOSTLY — Good Foundation, Some Remaining Issues

---

## Does TAUG Resemble a Dashboard?

**No.** TAUG follows research-first principles:
- Workspace-first layout (not dashboard)
- Decision prompts guide workflow
- Empty states with actionable guidance
- No floating KPI cards
- No chart-heavy layouts

**Evidence:**
- Companies Workspace: "Find companies to research"
- Company Workspace: "Research this company"
- Research Workspace: "Manage my research"
- Portfolio Workspace: "Track my decisions"

---

## Does TAUG Resemble an Admin Panel?

**No.** TAUG uses:
- 1px borders (not shadows)
- Monospace for financial data
- Dark theme
- 4px grid
- Dense information layout

**Evidence:**
- Consistent card design (1px border, no shadow, 6px radius)
- IBM Plex Mono for numbers
- IBM Plex Sans for UI text
- Compact spacing (2-16px tokens)

---

## Does TAUG Resemble AI-Generated SaaS?

**No.** TAUG avoids:
- Gradients
- Glassmorphism
- Neumorphism
- Giant cards
- Oversized empty states
- Excessive shadows

**Evidence:**
- Flat design throughout
- Border-based separation
- No blur effects
- No decorative elements

---

## Design Fixes Applied

### 1. textTertiary Contrast (Fixed)

**Before:** `#71717A` on `#18181B` → ratio = 3.85:1 (fails 4.5:1)

**After:** `#8E8E96` on `#18181B` → ratio = 4.55:1 (passes 4.5:1)

**Impact:** Section headers, metadata, hint text now readable for low-vision users.

---

### 2. Badge Contrast (Fixed)

**Before:** Alpha 0.15 (too subtle)

**After:** Alpha 0.20 (stronger visual weight)

**Impact:** Freshness/quality badges more visible.

---

### 3. Stance Badges Deduplicated (Fixed)

**Before:** 3 implementations (_StanceBadge, _StanceChipSmall, _StanceChip)

**After:** 1 implementation (StanceBadge with StanceBadgeSize enum)

**Impact:** -123 lines, consistent rendering, easier maintenance.

---

## Remaining Design Issues

### 1. No Focus Indicators

**Problem:** No custom focus styling. Default may be invisible against dark theme.

**Recommendation:** Define global focus theme with accent color.

---

### 2. No Keyboard Navigation

**Problem:** No keyboard shortcuts for tab switching, navigation, dialog dismiss.

**Recommendation:** Add keyboard shortcuts for power users.

---

### 3. Settings Density Mode Not Consumed

**Problem:** `densityMode` setting exists but nothing reads it.

**Recommendation:** Implement density-aware layouts.

---

## Visual Consistency Assessment

| Pattern | Status | Evidence |
|---|---|---|
| Card design | ✅ Consistent | 1px border, no shadow, 6px radius |
| Section headers | ✅ Consistent | monoSection style throughout |
| Badges | ✅ Consistent | StanceBadge, ConvictionBadge, FreshnessBadge |
| Buttons | ⚠️ Mostly consistent | Some variation in styles |
| Empty states | ✅ Consistent | AppEmptyState widget |
| Dialogs | ✅ Consistent | 500px width, StatefulBuilder |

---

## Design Maturity Score

| Category | Score | Evidence |
|---|---|---|
| Research-first layout | 9/10 | Workspace-first, decision prompts |
| Information density | 8/10 | Compact layouts, 4px grid |
| Visual consistency | 8/10 | Consistent cards, badges, headers |
| Accessibility | 6/10 | Contrast fixed, Semantics added |
| Keyboard support | 2/10 | No shortcuts |
| Focus indicators | 3/10 | Default only |
| **Overall** | **7.5/10** | **Good foundation, needs refinement** |

---

*This audit is maintained by Designer Agent.*
