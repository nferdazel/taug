# RC4 Code Quality Report

**Date:** 2026-06-22
**Status:** Complete

---

## Issues Found

| Severity | Count | Fixed | Deferred |
|---|---|---|---|
| Critical | 6 | 3 | 3 |
| High | 14 | 6 | 8 |
| Medium | 18 | 0 | 18 |
| Low | 12 | 0 | 12 |
| **Total** | **50** | **9** | **41** |

---

## Issues Fixed

### Critical (3 fixed)

1. **Direct Supabase in portfolio_workspace_page** — Extracted to repository + provider
2. **Missing dispose() on 5 providers/pages** — SettingsProvider, SymbolSearchProvider, CompaniesProvider, CompanyWorkspacePage, ResearchWorkspacePage
3. **Unused imports removed**

### High (6 fixed)

1. **Hardcoded colors** → AppThemeColors (app_router, app_section_header, portfolio_workspace_page)
2. **Hardcoded font sizes** → AppTypography (price_cell, calendar_page)
3. **Hardcoded spacing** → AppSpacing (portfolio_workspace_page)
4. **Duplicated _extractSnapshot** → Extracted to extensions.dart (3 repositories)
5. **Duplicated _formatDate** → Extracted to extensions.dart (5 files)
6. **Duplicated _formatTime** → Extracted to extensions.dart (3 files)

---

## Deferred Issues

### Critical (3 deferred)

1. **Direct Supabase in screener_page** — Needs ScreenerRepository + ScreenerProvider
2. **Direct Supabase in valuation_page** — Needs ValuationRepository + ValuationProvider
3. **Duplicate PortfolioRepository class name** — Needs rename

### High (8 deferred)

1. **Oversized widgets** — research_tab (1607 lines), portfolio_workspace_page (1454 lines)
2. **Business logic in widgets** — Supabase queries in dialogs
3. **setState in screener/valuation** — Need migration to signals
4. **InputDecoration duplication** — 12 copies in research_tab
5. **Hardcoded URLs** — Binance, Twelve Data endpoints
6. **ticker field never mapped** — Workspace prices broken
7. **Dead features** — 9 pages unreachable via router
8. **Unused providers** — NewsProvider, CalendarProvider, ChartProvider

---

## Code Quality Score

| Metric | Before | After | Target |
|---|---|---|---|
| Direct Supabase in UI | 6 files | 3 files | 0 |
| Missing dispose() | 5 providers | 0 | 0 |
| Hardcoded colors | ~10 | ~7 | 0 |
| Hardcoded font sizes | ~15 | ~13 | 0 |
| Hardcoded spacing | ~10 | ~8 | 0 |
| Duplicated utilities | 5 functions | 0 | 0 |
| **Overall Score** | **5/10** | **6/10** | **8/10** |

---

## Risk Assessment

| Risk | Probability | Impact | Status |
|---|---|---|---|
| Screener/Valuation direct Supabase | Medium | Medium | Deferred |
| Duplicate PortfolioRepository | Low | Medium | Deferred |
| Oversized widgets | Medium | Low | Deferred |
| Dead features | Low | Low | Deferred |

---

*Code quality is a journey, not a destination.*
