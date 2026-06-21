# TAUG Architecture Drift Report

**Created:** 2026-06-21
**Purpose:** Detect deviation from TAUG philosophy and architecture.

---

## Philosophy Alignment

### Core Workflow: Research → Decision → Portfolio → Learning

| Stage | Alignment | Status |
|---|---|---|
| Research | ✅ Strong | Company workspace with thesis, notes, financials |
| Decision | ✅ Strong | Thesis → Position bridge implemented |
| Portfolio | ✅ Strong | Decision tracking with outcome recording |
| Learning | ✅ Strong | Lessons aggregation view with outcome grouping |

**Assessment:** Core workflow is well-aligned. The B2 work (thesis → position bridge, lessons aggregation) significantly strengthened the workflow continuity.

---

## What Has Drifted

### Drift 1: Inline Supabase Queries in Presentation Layer

**Location:** `lib/features/portfolio/presentation/pages/portfolio_workspace_page.dart` lines 254-262

**What Happened:** Add Position dialog queries Supabase directly for company search and thesis fetch, bypassing the repository pattern.

**Why It Drifted:** Rapid implementation to ship the thesis → position bridge. Repository pattern would have required creating new repository methods.

**Impact:** 
- Harder to test (can't mock repository)
- Harder to maintain (queries scattered across presentation layer)
- Inconsistent with rest of codebase

**Correction:** Refactor to use repository pattern. Create `PortfolioWorkspaceRepository.searchCompanies()` and `PortfolioWorkspaceRepository.getThesesForCompany()`.

**Priority:** Medium — functional but architecturally impure.

---

### Drift 2: Legacy Holdings System Coexists

**Location:** `lib/features/portfolio/presentation/providers/portfolio_provider.dart` (holdings) vs `portfolio_workspace_provider.dart` (positions)

**What Happened:** Two separate portfolio systems exist:
- Legacy: `portfolio_holdings` table + `PortfolioProvider` (holdings CRUD)
- New: `portfolio_positions` table + `PortfolioWorkspaceProvider` (decision journal)

**Why It Drifted:** Historical evolution. Legacy system was built first, new system added for research workflow.

**Impact:**
- User confusion (which portfolio to use?)
- Duplicate class names (now fixed with rename)
- Two different data models for similar concepts

**Correction:** 
- Option A: Deprecate legacy holdings, migrate users to positions
- Option B: Clearly separate with different navigation labels
- Option C: Merge into unified portfolio system

**Priority:** Medium — functional but confusing.

---

### Drift 3: Settings Page Doesn't Observe Mutation Errors

**Location:** `lib/features/settings/presentation/pages/settings_page.dart`

**What Happened:** Settings provider now sets `error.value` on mutation failure, but settings page never reads or displays it.

**Why It Drifted:** B1.1 added error propagation to providers but didn't update all UI surfaces.

**Impact:**
- Silent failures for timezone/density changes
- User thinks change succeeded but it didn't

**Correction:** Add Watch widget to observe `error.value` and display snackbar or inline error.

**Priority:** Medium — silent failure for non-critical settings.

---

### Drift 4: No Repository Pattern for Data Workspace

**Location:** `lib/features/data/presentation/pages/data_workspace_page.dart`

**What Happened:** Data workspace page is a placeholder stub. No repository or provider exists for system-wide trust data.

**Why It Drifted:** B3 focused on company-level trust, not system-wide trust.

**Impact:**
- No centralized view of data health
- Users can't see "which companies have stale data"

**Correction:** Create `DataWorkspaceRepository` and `DataWorkspaceProvider` to fetch from `company_freshness_v`, `data_quality_scores`, `company_data_quality_v`.

**Priority:** Low — company-level trust is sufficient for now.

---

### Drift 5: Some Repositories Use Raw Strings Instead of AppSchema Constants

**Location:** `lib/features/portfolio/data/portfolio_workspace_repository.dart`, `lib/features/company/data/workspace_repository.dart`

**What Happened:** Some repositories use raw table names (`'companies'`, `'securities'`) instead of `AppSchema` constants.

**Why It Drifted:** Inconsistent coding standards during rapid implementation.

**Impact:**
- If schema name changes, need to update multiple files
- Inconsistent with rest of codebase

**Correction:** Replace all raw strings with `AppSchema` constants.

**Priority:** Low — functional but inconsistent.

---

## What No Longer Aligns

### 1. Dashboard Patterns (Removed ✅)

**Status:** Corrected in B2

The codebase has moved away from dashboard patterns:
- Research workspace is action-oriented ("Needs Thesis")
- Company overview has decision prompt
- Portfolio workspace is a decision journal
- No counter badges, no passive metric grids

---

### 2. Metrics-First Thinking (Corrected ✅)

**Status:** Corrected in B2, B3

Metrics are now contextualized within research:
- DATA TRUST section provides context for metrics
- Freshness indicators on each metric
- Quality breakdown accessible from badge
- Metrics serve research, not the other way around

---

### 3. Terminal Patterns (Partially Removed)

**Status:** Some terminal patterns remain

Remaining terminal patterns:
- Order book (synthetic data, not implemented)
- Running trades (synthetic data, not implemented)
- Market movers (implemented but not core workflow)
- Real-time prices (daily sync only, not terminal-grade)

**Assessment:** These are legacy features from the terminal pivot. They don't serve the research workflow but aren't harmful.

---

## What Should Be Corrected Later

### Priority 1: Refactor Inline Supabase Queries

**When:** Before B2 is considered "done"
**Effort:** Small (2-3 hours)
**Impact:** Architecture cleanliness

### Priority 2: Deprecate or Separate Legacy Holdings

**When:** Before production launch
**Effort:** Medium (1-2 days)
**Impact:** User confusion reduction

### Priority 3: Add Settings Mutation Error UI

**When:** Before production launch
**Effort:** Small (1-2 hours)
**Impact:** UX improvement

### Priority 4: Implement Data Workspace

**When:** After production launch
**Effort:** Medium (2-3 days)
**Impact:** System-wide trust visibility

### Priority 5: Replace Raw Strings with AppSchema Constants

**When:** Anytime
**Effort:** Small (1-2 hours)
**Impact:** Code consistency

---

## Architecture Health Score

| Category | Score | Notes |
|---|---|---|
| Workflow Alignment | 9/10 | Strong Research → Decision → Portfolio → Learning |
| Code Consistency | 7/10 | Some inline queries, raw strings |
| Pattern Adherence | 8/10 | Repository pattern mostly followed |
| Philosophy Alignment | 9/10 | Research-first, not dashboard-first |
| Technical Debt | 6/10 | Legacy systems, missing tests |

**Overall Architecture Health:** 7.8/10

---

*This report is updated after each phase. Drift should be corrected before it becomes debt.*
