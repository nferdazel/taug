# TAUG Risk Register

**Date:** 2026-06-22
**Purpose:** Track unresolved risks.

---

## Active Risks

### R1: Learning Loop Not Implemented

**Probability:** High (design complete, implementation pending)
**Impact:** Critical (core promise unfulfilled)
**Mitigation:** Implement surface company lessons in thesis dialog (~100 lines)
**Owner:** Frontend-1, Backend-1
**Status:** Open
**Phase Identified:** P0.1

---

### R2: Research Intelligence Not Implemented

**Probability:** High (design complete, implementation pending)
**Impact:** High (TAUG is workspace, not operating system)
**Mitigation:** Implement P0 features (freshness, status, Mark Reviewed)
**Owner:** Backend-2, Frontend-2
**Status:** Open
**Phase Identified:** P0.1

---

### R3: Testing: 3/10

**Probability:** High (minimal test coverage)
**Impact:** High (no regression detection)
**Mitigation:** Add unit tests for repositories and providers
**Owner:** QA-1
**Status:** Open
**Phase Identified:** Production Program

---

### R4: Accessibility: 6/10

**Probability:** Medium (improved but gaps remain)
**Impact:** Medium (some users excluded)
**Mitigation:** Add Semantics to interactive widgets, keyboard navigation
**Owner:** A11Y, Frontend-3
**Status:** Open
**Phase Identified:** Production Program

---

### R5: .env Contains Live Keys

**Probability:** High (file exists on disk)
**Impact:** High (service role key bypasses all RLS)
**Mitigation:** Rotate all API keys, move service role key out of .env
**Owner:** DevOps
**Status:** Open
**Phase Identified:** Production Program

---

### R6: Debug Logging Leaks PII

**Probability:** Medium (debugPrint in auth repository)
**Impact:** Medium (emails and UUIDs in console)
**Mitigation:** Wrap sensitive logging in kDebugMode
**Owner:** Backend-1
**Status:** Open
**Phase Identified:** Production Program

---

### R7: Position → Company Context Loss

**Probability:** Medium (not yet fixed)
**Impact:** Medium (user must mentally track position)
**Mitigation:** Add back-navigation breadcrumb
**Owner:** Frontend-2
**Status:** Open
**Phase Identified:** P0.1

---

### R8: No Focus Indicators

**Probability:** Medium (not implemented)
**Impact:** Medium (keyboard users affected)
**Mitigation:** Define global focus theme
**Owner:** Designer
**Status:** Open
**Phase Identified:** Production Program

---

### R9: No Keyboard Navigation

**Probability:** Medium (not implemented)
**Impact:** Medium (power users affected)
**Mitigation:** Add keyboard shortcuts
**Owner:** Frontend-3
**Status:** Open
**Phase Identified:** Production Program

---

### R10: Single Thesis Display

**Probability:** Low (only first thesis shown)
**Impact:** Medium (evolution not visible)
**Mitigation:** Show all theses with status badges
**Owner:** Frontend-1
**Status:** Open
**Phase Identified:** P0.1

---

## Closed Risks

### R11: Thesis → Position Context Loss (CLOSED)

**Probability:** High (was critical workflow break)
**Impact:** High (~60 seconds wasted per position)
**Mitigation:** Pre-populate dialog via query parameters
**Owner:** God-2
**Status:** Closed
**Phase Identified:** P0.1
**Resolution:** Fixed with query parameter passing

---

### R12: markReviewNeeded Dead Code (CLOSED)

**Probability:** High (method never called)
**Impact:** High (review workflow half-implemented)
**Mitigation:** Wire to position lifecycle
**Owner:** God-2
**Status:** Closed
**Phase Identified:** P0.1
**Resolution:** "Mark for Review" added to position menu

---

### R13: Lessons → Research Dead End (CLOSED)

**Probability:** High (no path from lessons to research)
**Impact:** High (lessons are dead-end records)
**Mitigation:** "Apply to New Research" button on lesson cards
**Owner:** God-2
**Status:** Closed
**Phase Identified:** P0.1
**Resolution:** Navigation to company Research tab

---

### R14: textTertiary Contrast Too Low (CLOSED)

**Probability:** High (3.85:1 ratio)
**Impact:** Medium (low-vision users affected)
**Mitigation:** Change to #8E8E96 (4.55:1 ratio)
**Owner:** Designer
**Status:** Closed
**Phase Identified:** P0.1
**Resolution:** Color updated in app_theme_colors.dart

---

### R15: Stance Badge Duplication (CLOSED)

**Probability:** High (3 implementations)
**Impact:** Low (maintenance burden)
**Mitigation:** Deduplicate to single StanceBadge widget
**Owner:** Designer
**Status:** Closed
**Phase Identified:** P0.1
**Resolution:** 3 → 1 implementation, -123 lines

---

## Risk Summary

| Status | Count |
|---|---|
| Open | 10 |
| Closed | 5 |
| **Total** | **15** |

---

## Top Risks by Impact

1. **R1: Learning Loop Not Implemented** — Critical
2. **R2: Research Intelligence Not Implemented** — High
3. **R3: Testing: 3/10** — High
4. **R5: .env Contains Live Keys** — High
5. **R4: Accessibility: 6/10** — Medium

---

*This register is continuously updated. Open risks require mitigation plans.*
