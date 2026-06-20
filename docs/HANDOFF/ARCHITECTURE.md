# TAUG — Architecture

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter Web (WASM) | Desktop-first web application |
| Language | Dart SDK ^3.12.2 | Type-safe development |
| State | signals ^6.0.0 | Fine-grained reactive state |
| Routing | go_router ^14.8.1 | Declarative routing with deep links |
| Database | Supabase (PostgreSQL) | Auth, storage, real-time |
| Schema | `taug` | Isolated schema for TAUG data |
| Workers | Python 3.12+ | SEC data pipeline, macro data |
| Scheduling | GitHub Actions | CI/CD + scheduled data jobs |
| Hosting | Vercel | Flutter Web deployment |

---

## Flutter Web Strategy

TAUG is a Flutter Web application compiled to WASM.

**Why Flutter Web:**
- Cross-platform consistency
- Strong typing (Dart)
- Widget composition model
- Single codebase for web + future mobile
- WASM performance for data-heavy UIs

**Why NOT React/Vue:**
- Flutter's type safety prevents runtime errors
- Widget composition is more consistent than JSX
- Existing codebase is 100% Dart
- No framework fragmentation

**Key constraint:** Flutter Web is the target platform. No migration to other frameworks.

---

## Signals Architecture

State management uses the `signals` package.

**Pattern:**
```dart
// Global signals
final activeCompanyId = Signal<String?>(null);
final isLoading = Signal<bool>(false);

// Computed signals
final filteredCompanies = Computed(() {
  return companies.where((c) => c.isActive).toList();
});

// Widget binding
Watcher((context) {
  return Text(activeCompanyId.value ?? 'None');
});
```

**Why signals:**
- Minimal boilerplate
- Fine-grained rebuilds
- Direct widget integration
- No Bloc/Riverpod complexity

---

## Routing Architecture

go_router with ShellRoute for workspace navigation.

**Route structure:**
```
/login
/register
/companies (Companies Workspace)
/companies/:id (Company Workspace)
/companies/:id/overview
/companies/:id/financials
/companies/:id/research
/research (Research Workspace)
/portfolio-workspace (Portfolio Workspace)
/data (Data Workspace)
/settings (Settings)
```

**Legacy routes redirect:** `/brief`, `/market`, `/chart`, etc. redirect to `/companies`.

---

## State Management

| Category | Tool | Scope |
|---|---|---|
| Global UI | `Signal` | Active company, theme |
| Workspace UI | `Signal` (scoped) | Screener filters, sort |
| Server state | Repository pattern | Supabase queries |
| Form state | `TextEditingController` | Per-form |

---

## Repository Layer

Every data access goes through a repository.

```dart
class CompanyRepository {
  final SupabaseClient _client;
  
  Future<Result<CompanyProfile>> getCompanyProfile(String companyId) async {
    // Query Supabase
    // Return Result<T>
  }
}
```

**Pattern:** Repository → Supabase → Result<T>

**Error handling:** All repositories return `Result<T>` (success/failure). Never throw.

---

## Data Layer

### Supabase

- **Schema:** `taug` (isolated from public schema)
- **Auth:** Supabase Auth (username + password)
- **RLS:** Row-level security on user-owned tables
- **Views:** 8 serving views for Flutter reads

### Python Workers

| Worker | Purpose |
|---|---|
| `sync-sec-submissions` | Fetch SEC EDGAR submissions |
| `sync-sec-companyfacts` | Fetch XBRL companyfacts |
| `parse-sec-companyfacts` | Parse into financial statements |
| `compute-company-metrics` | Compute 19 metrics |
| `sync-price-snapshots` | Fetch prices from Twelve Data |
| `execute-screener` | Execute saved screeners |
| `compute-data-quality` | Compute quality scores |
| `sync-fred-series` | Fetch FRED macro data |
| `sync-bps-series` | Fetch BPS macro data |

---

## Design Decisions

### Decision 1: Flutter over React
**Choice:** Flutter Web
**Rationale:** Type safety, widget consistency, existing codebase, WASM performance
**Trade-off:** Smaller web ecosystem than React

### Decision 2: Signals over Bloc/Riverpod
**Choice:** signals package
**Rationale:** Minimal boilerplate, fine-grained rebuilds, direct widget integration
**Trade-off:** Less tooling than Bloc

### Decision 3: Supabase over custom backend
**Choice:** Supabase
**Rationale:** Auth, storage, real-time, PostgreSQL — all in one service
**Trade-off:** Vendor dependency

### Decision 4: Python workers over Dart workers
**Choice:** Python for data pipeline
**Rationale:** Better ecosystem for XBRL parsing, HTTP clients, data processing
**Trade-off:** Two languages in the project

### Decision 5: Desktop-first over mobile-first
**Choice:** Desktop Web
**Rationale:** Research requires screen space, dense data, keyboard access
**Trade-off:** Mobile experience is secondary

### Decision 6: Dark mode only
**Choice:** Dark theme
**Rationale:** Research platforms work better in dark mode, reduces eye strain
**Trade-off:** No light mode option
