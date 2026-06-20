# B1 — Beta Hardening Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Executive Summary

Fixed 5 critical production readiness issues, 2 medium issues. Flutter analyze passes with 0 issues. Application is ready for beta testing with 100 users.

---

## Issues Found and Fixed

### Critical (Fixed)

| # | Issue | File | Fix |
|---|---|---|---|
| 1 | Auth navigates to dead `/brief` route | `auth_provider.dart` | Changed to `/companies` |
| 2 | Silent error in portfolio company search | `portfolio_workspace_page.dart` | Added `debugPrint` and error handling |
| 3 | ResearchProvider has no error handling | `research_provider.dart` | Added try/catch and error signal |
| 4 | No delete confirmation dialogs | `research_tab.dart` | Added `_confirmDelete` helper |
| 5 | Sub-route stubs render blank screens | `app_router.dart` | Changed to redirects |

### Medium (Fixed)

| # | Issue | File | Fix |
|---|---|---|---|
| 6 | Text overflow in research notes | `research_tab.dart` | Added `maxLines: 1, overflow: TextOverflow.ellipsis` |
| 7 | Unnecessary underscores in router | `app_router.dart` | Changed `__` to `_` |

### Medium (Not Fixed — Documented)

| # | Issue | Impact | Recommendation |
|---|---|---|---|
| 8 | TextEditingControllers leaked in dialogs | Memory leak on repeated open/close | Move to StatefulWidget classes |
| 9 | Provider mutations silently fail | User sees no feedback on error | Add SnackBar error display |
| 10 | No RepaintBoundary on cards | Performance on large lists | Add RepaintBoundary wrapping |

### Low (Not Fixed — Documented)

| # | Issue | Recommendation |
|---|---|---|
| 11 | Duplicated `_formatDate` in 6 files | Extract to shared utility |
| 12 | Duplicated stance/conviction chips | Extract to shared widget |
| 13 | Settings page missing loading/error states | Add Watch wrapper |
| 14 | DataWorkspacePage is a stub | Implement or remove tab |
| 15 | No keyboard shortcuts | Add Shortcuts widget |

---

## Production Readiness Assessment

### Would I ship this to 100 users?

**Yes, with caveats.**

**What works:**
- Core workflow: Company → Research → Thesis → Position → Close
- All CRUD operations (notes, theses, positions)
- Navigation between all workspaces
- Search across companies, theses, notes
- Trust indicators (quality, freshness)
- Decision prompt guidance

**What needs monitoring:**
- Silent error handling on mutations (user sees no feedback)
- TextEditingControllers in dialogs (memory leak over time)
- Large dataset performance (32+ companies)

**What is NOT a blocker:**
- Missing RepaintBoundary (performance optimization, not correctness)
- Duplicated code (maintenance issue, not user-facing)
- No keyboard shortcuts (UX enhancement, not blocker)

---

## Remaining Design Debt

| Item | Priority | Impact |
|---|---|---|
| Silent mutation errors | High | User confusion |
| Dialog controller leaks | Medium | Memory over time |
| Text overflow in dense views | Medium | Visual bugs |
| No RepaintBoundary | Low | Performance |
| Duplicated utilities | Low | Maintenance |

---

## Recommendation

1. **Ship to beta.** Core workflow is solid. No critical blockers.
2. **Monitor:** Silent errors, memory usage, performance with real users.
3. **Next iteration:** Fix silent errors, add keyboard shortcuts, extract shared utilities.
