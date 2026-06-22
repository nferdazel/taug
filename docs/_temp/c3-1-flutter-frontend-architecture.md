# C3.1 — Flutter Frontend Architecture

**Date:** 2026-06-20
**Type:** Technical architecture — no implementation
**Constraint:** Flutter is non-negotiable. React/Vue/Svelte not considered.

---

## Executive Summary

TAUG's frontend is built entirely in Flutter. The C3 recommendation for React was incorrect — Flutter is the mandated platform. This document redesigns the frontend architecture around Flutter's strengths: cross-platform consistency, strong typing, widget composition, and the existing codebase. The primary challenge is table rendering for financial data, which is solved with a hybrid approach using `syncfusion_flutter_datagrid` for dense data tables and custom widgets for research content.

---

## C3 Assumption Review

### Assumptions That Were Wrong

| C3 Claim | Reality |
|---|---|
| "React's table ecosystem is 10x larger" | Syncfusion DataGrid provides comparable functionality for financial tables |
| "Flutter has no mature rich text editor" | `flutter_quill` or `super_editor` provide adequate rich text for research notes |
| "React component ecosystem is superior" | Flutter's widget system is more consistent and type-safe |
| "Flutter Web is slow for data-heavy UIs" | WASM compilation + RepaintBoundary + signals = adequate performance |
| "Developer experience is better in React" | Subjective. Flutter's hot reload + type safety is excellent DX |

### What Flutter Does Well (That C3 Underestimated)

1. **Type safety.** Every widget, every state, every data flow is fully typed. No runtime type errors.
2. **Widget composition.** Compound components work naturally with Flutter's widget tree.
3. **Cross-platform.** Same codebase for Web, Desktop, Mobile. No migration needed later.
4. **Consistency.** One framework, one language, one rendering engine. No framework fragmentation.
5. **Existing codebase.** 71 Dart files, 10,500 lines already written. Starting from scratch in React would waste all of it.

---

## Flutter Application Architecture

### Feature-First Structure

```
lib/
├── core/
│   ├── config/           # AppEnv, AppRouter
│   ├── constants/        # AppColors, AppStrings
│   ├── errors/           # Failure, Result
│   ├── network/          # SupabaseClient, ApiClient
│   ├── schema/           # Table/view name constants
│   ├── theme/            # Design tokens, typography, spacing
│   └── utils/            # Extensions, formatters
├── features/
│   ├── dashboard/        # Dashboard workspace
│   ├── companies/        # Company list + Company Workspace
│   ├── screener/         # Screener workspace
│   ├── research/         # Notes, theses, watchlists
│   ├── comparison/       # Company comparison
│   ├── portfolio/        # Portfolio tracking
│   ├── data/             # Data quality, freshness, sources
│   ├── settings/         # User preferences
│   └── layout/           # App shell, navigation
├── shared/
│   ├── models/           # Domain entities
│   ├── widgets/          # Reusable components
│   └── services/         # Shared business logic
└── main.dart
```

### Feature Module Structure

```
features/companies/
├── data/
│   ├── company_repository.dart
│   ├── company_models.dart
│   └── company_queries.dart
├── domain/
│   └── company_entity.dart
└── presentation/
    ├── pages/
    │   ├── company_list_page.dart
    │   └── company_workspace_page.dart
    ├── widgets/
    │   ├── company_header.dart
    │   ├── company_tabs.dart
    │   ├── metric_card.dart
    │   └── financial_statement_table.dart
    └── providers/
        └── company_provider.dart
```

---

## Routing Architecture

### go_router Configuration

```dart
final router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(
          path: '/companies',
          builder: (_, __) => const CompanyListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => CompanyWorkspacePage(
                companyId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(path: 'overview', builder: (_, __) => const CompanyOverviewTab()),
                GoRoute(path: 'financials', builder: (_, __) => const CompanyFinancialsTab()),
                GoRoute(path: 'valuation', builder: (_, __) => const CompanyValuationTab()),
                GoRoute(path: 'research', builder: (_, __) => const CompanyResearchTab()),
                GoRoute(path: 'data', builder: (_, __) => const CompanyDataTab()),
              ],
            ),
          ],
        ),
        GoRoute(path: '/screener', builder: (_, __) => const ScreenerPage()),
        GoRoute(
          path: '/research',
          builder: (_, __) => const ResearchPage(),
          routes: [
            GoRoute(path: 'notes', builder: (_, __) => const NotesListPage()),
            GoRoute(path: 'theses', builder: (_, __) => const ThesesListPage()),
            GoRoute(path: 'watchlists', builder: (_, __) => const WatchlistsPage()),
          ],
        ),
        GoRoute(path: '/compare/:idA/:idB', builder: (_, state) => ComparisonPage(
          companyAId: state.pathParameters['idA']!,
          companyBId: state.pathParameters['idB']!,
        )),
        GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioPage()),
        GoRoute(path: '/data', builder: (_, __) => const DataPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      ],
    ),
  ],
);
```

### Deep Linking

go_router supports deep linking natively. URLs like `/companies/aapl/financials` work directly.

---

## State Architecture

### Signals-First Approach

```dart
// Global signals
final activeCompanyId = Signal<String?>(null);
final themeMode = Signal<ThemeMode>(ThemeMode.dark);

// Workspace signals (scoped to feature)
class ScreenerState {
  final filters = ListSignal<ScreenerFilter>([]);
  final sortBy = Signal<String>('market_cap');
  final sortDirection = Signal<SortDirection>(SortDirection.desc);
  final results = ListSignal<ScreenerResult>([]);
  final isLoading = Signal<bool>(false);
}

// Async data with computed signals
final companies = AsyncSignal<List<Company>>(() => fetchCompanies());
final companyMetrics = Computed(() {
  final id = activeCompanyId.value;
  if (id == null) return null;
  return fetchMetrics(id);
});
```

### State Categories

| Category | Tool | Scope | Example |
|---|---|---|---|
| Global UI | `Signal` | App-wide | Active company, theme |
| Workspace UI | `Signal` (scoped) | Per-workspace | Screener filters, sort |
| Async data | `AsyncSignal` | Per-query | Companies, metrics |
| Computed | `Computed` | Derived | Filtered results |
| Form state | `TextEditingController` | Per-form | Note editor |
| Transient | `ValueNotifier` | Per-widget | Hover, modal open |

### Signals vs Other Patterns

| Pattern | Signals | Bloc | Riverpod |
|---|---|---|---|
| Boilerplate | Minimal | High | Medium |
| Learning curve | Low | High | Medium |
| Rebuild granularity | Fine | Medium | Fine |
| DevTools | Basic | Excellent | Good |
| Widget integration | Direct | Builder | Consumer |

**Decision: Signals-first.** Minimal boilerplate, fine-grained rebuilds, direct widget integration.

---

## Data Access Architecture

### Repository Pattern

```dart
class CompanyRepository {
  final SupabaseClient _client;

  CompanyRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<Company>> getCompanies() async {
    final response = await _client
        .from(AppSchema.companies)
        .select()
        .eq('ingestion_enabled', true);
    return (response as List).map(Company.fromMap).toList();
  }

  Future<CompanyResearchSummary> getCompanySummary(String companyId) async {
    final response = await _client
        .from(AppSchema.companyResearchSummary)
        .select()
        .eq('company_id', companyId)
        .single();
    return CompanyResearchSummary.fromMap(response);
  }

  Future<List<CompanyMetricSnapshot>> getMetrics(String companyId) async {
    final response = await _client
        .from(AppSchema.companyMetricSnapshot)
        .select()
        .eq('company_id', companyId);
    return (response as List).map(CompanyMetricSnapshot.fromMap).toList();
  }
}
```

### Caching Strategy

```dart
// Simple in-memory cache with TTL
class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  final Duration ttl;

  CacheEntry(this.data, this.fetchedAt, this.ttl);

  bool get isFresh => DateTime.now().difference(fetchedAt) < ttl;
}

class CachedRepository {
  final _cache = <String, CacheEntry>{};

  Future<T> cached<T>(String key, Duration ttl, Future<T> Function() fetcher) async {
    final entry = _cache[key];
    if (entry != null && entry.isFresh) {
      return entry.data as T;
    }
    final data = await fetcher();
    _cache[key] = CacheEntry(data, DateTime.now(), ttl);
    return data;
  }
}
```

### Query Pattern

```dart
// Provider-style data access
class CompanyProvider {
  final CompanyRepository _repository;

  final companies = Signal<List<Company>>([]);
  final isLoading = Signal<bool>(false);

  Future<void> loadCompanies() async {
    isLoading.value = true;
    companies.value = await _repository.getCompanies();
    isLoading.value = false;
  }
}
```

---

## Table Strategy

### The Core Challenge

Flutter's built-in `DataTable` is basic. TAUG needs:
- Sorting by any column
- Filtering
- Column visibility toggle
- Frozen first column
- Virtualization for 100+ rows
- Comparison layouts (side-by-side)
- Dense financial data display

### Recommended Approach: Syncfusion DataGrid

`syncfusion_flutter_datagrid` provides:
- Column sorting
- Column resizing
- Column visibility
- Frozen columns/rows
- Built-in scrolling
- Cell customization
- Theme integration

```dart
SfDataGrid(
  source: _companyDataSource,
  columns: [
    GridColumn(columnName: 'company', label: Text('Company'), frozen: FrozenColumn.start),
    GridColumn(columnName: 'pe', label: Text('PE')),
    GridColumn(columnName: 'roe', label: Text('ROE')),
    GridColumn(columnName: 'debt_equity', label: Text('D/E')),
    GridColumn(columnName: 'quality', label: Text('Quality')),
  ],
  frozenColumnsCount: 1, // Freeze first column
  allowSorting: true,
  allowFiltering: true,
)
```

### Financial Statement Table

For financial statements (income statement, balance sheet), use a custom table with fixed structure:

```dart
class FinancialStatementTable extends StatelessWidget {
  final List<FinancialStatementRow> rows;
  final List<String> periods;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        columns: [
          DataColumn(label: Text('')), // Line item label
          ...periods.map((p) => DataColumn(
            label: Text(p, style: AppTypography.monoLabel),
            numeric: true,
          )),
        ],
        rows: rows.map((row) => DataRow(
          cells: [
            DataCell(Text(row.label, style: AppTypography.body)),
            ...row.values.map((v) => DataCell(
              Text(formatFinancial(v), style: AppTypography.monoData),
            )),
          ],
        )).toList(),
      ),
    );
  }
}
```

### Screener Table

For the screener (sortable, filterable, 32+ rows), use Syncfusion DataGrid:

```dart
class ScreenerTable extends StatelessWidget {
  final List<ScreenerResult> results;

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: ScreenerDataSource(results),
      columns: [
        GridColumn(columnName: 'company', label: Text('Company'), frozen: FrozenColumn.start),
        GridColumn(columnName: 'sector', label: Text('Sector')),
        GridColumn(columnName: 'pe', label: Text('PE'), allowSorting: true),
        GridColumn(columnName: 'pb', label: Text('PB'), allowSorting: true),
        GridColumn(columnName: 'roe', label: Text('ROE'), allowSorting: true),
        GridColumn(columnName: 'debt_equity', label: Text('D/E'), allowSorting: true),
        GridColumn(columnName: 'market_cap', label: Text('MCap'), allowSorting: true),
        GridColumn(columnName: 'quality', label: Text('Quality')),
        GridColumn(columnName: 'freshness', label: Text('Fresh')),
      ],
      frozenColumnsCount: 1,
      allowSorting: true,
    );
  }
}
```

### Comparison Table

For comparison (side-by-side), use a custom layout:

```dart
class ComparisonTable extends StatelessWidget {
  final CompanyMetricSnapshot companyA;
  final CompanyMetricSnapshot companyB;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildColumn(companyA)),
        Container(width: 1, color: AppThemeColors.border),
        Expanded(child: _buildColumn(companyB)),
      ],
    );
  }
}
```

---

## Research Architecture

### Note Editor

Use `flutter_quill` for rich text editing:

```dart
class NoteEditor extends StatefulWidget {
  final String? initialContent;
  final Function(String content, List<String> tags) onSave;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late QuillController _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuillToolbar.simple(controller: _controller),
        Expanded(
          child: QuillEditor.basic(controller: _controller),
        ),
      ],
    );
  }
}
```

### Thesis Editor

Structured form with multiple sections:

```dart
class ThesisEditor extends StatefulWidget {
  final InvestmentThesis? initialThesis;
  final Function(InvestmentThesis) onSave;

  @override
  State<ThesisEditor> createState() => _ThesisEditorState();
}

class _ThesisEditorState extends State<ThesisEditor> {
  final _summaryController = TextEditingController();
  final _bullCaseController = TextEditingController();
  final _bearCaseController = TextEditingController();
  final _assumptionsController = TextEditingController();
  final _catalystsController = TextEditingController();
  final _risksController = TextEditingController();
  final _exitConditionsController = TextEditingController();
  ConvictionLevel _conviction = ConvictionLevel.low;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection('Summary', _summaryController),
        _buildSection('Bull Case', _bullCaseController),
        _buildSection('Bear Case', _bearCaseController),
        _buildSection('Key Assumptions', _assumptionsController),
        _buildSection('Catalysts', _catalystsController),
        _buildSection('Risks', _risksController),
        _buildSection('Exit Conditions', _exitConditionsController),
        _buildConvictionSelector(),
      ],
    );
  }
}
```

### Conviction Selector

```dart
class ConvictionSelector extends StatelessWidget {
  final ConvictionLevel value;
  final Function(ConvictionLevel) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ConvictionLevel>(
      segments: [
        ButtonSegment(value: ConvictionLevel.low, label: Text('Low')),
        ButtonSegment(value: ConvictionLevel.medium, label: Text('Medium')),
        ButtonSegment(value: ConvictionLevel.high, label: Text('High')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
```

---

## Trust Layer Architecture

### Trust Signal Propagation

```dart
// Trust data flows through providers, displayed via widgets
class CompanyTrustBar extends StatelessWidget {
  final String companyId;

  @override
  Widget build(BuildContext context) {
    final freshness = context.watch<CompanyFreshnessProvider>();
    final quality = context.watch<CompanyQualityProvider>();

    return Row(
      children: [
        FreshnessBadge(status: freshness.status),
        const SizedBox(width: 8),
        QualityBadge(score: quality.score),
        const SizedBox(width: 8),
        SourceBadge(source: freshness.source),
      ],
    );
  }
}
```

### Trust Components

```dart
class FreshnessBadge extends StatelessWidget {
  final FreshnessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.label, style: TextStyle(
        color: status.color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      )),
    );
  }
}

class QualityBadge extends StatelessWidget {
  final double score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: _scoreColor),
        const SizedBox(width: 4),
        Text('${(score * 100).round()}%', style: AppTypography.caption),
      ],
    );
  }
}
```

---

## Component Architecture

### Widget Hierarchy

```
App
├── MaterialApp.router (go_router)
└── MainLayout
    ├── NavigationBar (40px, fixed)
    └── Content Area
        ├── DashboardPage
        ├── CompanyListPage
        ├── CompanyWorkspacePage
        │   ├── CompanyHeader (identity + trust)
        │   ├── CompanyTabs (5 tabs)
        │   ├── CompanyOverviewTab
        │   │   ├── MetricGrid
        │   │   ├── RecentFilingsList
        │   │   └── DataQualitySummary
        │   ├── CompanyFinancialsTab
        │   │   └── FinancialStatementTable
        │   ├── CompanyValuationTab
        │   │   └── ValuationMetricGrid
        │   ├── CompanyResearchTab
        │   │   ├── ThesisCard
        │   │   └── NotesList
        │   └── CompanyDataTab
        │       ├── FreshnessDisplay
        │       └── SourceDisplay
        ├── ScreenerPage
        │   ├── ScreenerFilters
        │   └── ScreenerTable (SfDataGrid)
        ├── ResearchPage
        │   ├── NotesSidebar
        │   └── NoteEditor
        ├── ComparisonPage
        │   ├── CompanyColumn (left)
        │   └── CompanyColumn (right)
        ├── PortfolioPage
        │   ├── PositionTable
        │   └── AlertsList
        ├── DataPage
        │   ├── FreshnessDashboard
        │   ├── QualityScores
        │   └── SourceRegistry
        └── SettingsPage
```

---

## Performance Strategy

### Signals Rebuild Optimization

```dart
// Fine-grained rebuilds — only rebuild what changes
class MetricCard extends StatelessWidget {
  final String metricCode;
  final Computed<double?> value;

  @override
  Widget build(BuildContext context) {
    return Watcher((context) {
      final val = value.value;
      return Container(
        child: Text(val != null ? val.toStringAsFixed(2) : 'N/A'),
      );
    });
  }
}
```

### Table Virtualization

Syncfusion DataGrid handles virtualization internally. For custom tables, use `ListView.builder`:

```dart
ListView.builder(
  itemCount: rows.length,
  itemExtent: 28, // Fixed row height for performance
  itemBuilder: (context, index) {
    return FinancialStatementRowWidget(row: rows[index]);
  },
)
```

### RepaintBoundary

```dart
RepaintBoundary(
  child: MetricGrid(metrics: metrics), // Isolate expensive repaints
)
```

### WASM Compilation

Flutter Web WASM compilation provides near-native performance for:
- Widget rendering
- Signal computation
- Data processing

---

## Desktop Strategy

### Navigation

- **Tab bar:** 7 main tabs, always visible, 40px height
- **Keyboard:** 1-7 for tab switching, arrow keys for navigation
- **Deep linking:** go_router supports all workspace URLs

### Workspace Layouts

```dart
// Company Workspace: Tabbed content
class CompanyWorkspacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CompanyHeader(company: company),
        CompanyTabs(selected: currentTab, onChanged: onTabChanged),
        Expanded(child: _buildTabContent()),
      ],
    );
  }
}

// Screener: Filter panel + results table
class ScreenerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 240, child: ScreenerFilters()),
        VerticalDivider(width: 1),
        Expanded(child: ScreenerTable()),
      ],
    );
  }
}

// Research: Sidebar + editor
class ResearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 240, child: NotesSidebar()),
        VerticalDivider(width: 1),
        Expanded(child: NoteEditor()),
      ],
    );
  }
}

// Comparison: Side-by-side
class ComparisonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: CompanyColumn(company: companyA)),
        VerticalDivider(width: 1),
        Expanded(child: CompanyColumn(company: companyB)),
      ],
    );
  }
}
```

### Future Mobile Adaptation

When mobile support is needed:
- Collapse sidebar layouts to bottom sheets
- Convert tab bars to bottom navigation
- Stack comparison columns vertically
- Use `LayoutBuilder` for responsive breakpoints

---

## MVP Architecture

### Must Have

| Component | Rationale |
|---|---|
| go_router routing | Navigation |
| signals state management | Reactive UI |
| Supabase client | Data access |
| Company Workspace | Core research |
| Screener (SfDataGrid) | Discovery |
| Research (notes + theses) | Workflow |
| Portfolio | Tracking |
| Settings | Configuration |
| Trust badges | Data transparency |

### Should Have

| Component | Rationale |
|---|---|
| Comparison Workspace | Decision support |
| Data Workspace | Trust transparency |
| Dashboard | Convenience |
| flutter_quill editor | Rich notes |
| Metric charts | Visualization |

### Future

| Component | Rationale |
|---|---|
| Mobile adaptation | Reach |
| Offline support | Convenience |
| Real-time updates | Monitoring |

---

## Risks

### Table Performance

**Risk:** Large tables (100+ rows) may be slow on Web.

**Mitigation:** Syncfusion DataGrid handles virtualization. Custom tables use `ListView.builder` with `itemExtent`.

### Rich Text Editor

**Risk:** `flutter_quill` may have Web compatibility issues.

**Mitigation:** Test early. Fallback to plain `TextEditingController` if needed.

### Bundle Size

**Risk:** Syncfusion + flutter_quill = large WASM bundle.

**Mitigation:** Code splitting via deferred imports. Load heavy packages on demand.

### Signals Learning Curve

**Risk:** Team unfamiliar with signals pattern.

**Mitigation:** Signals is simpler than Bloc/Riverpod. Minimal boilerplate.

---

## Recommendation

1. **Flutter is the platform.** No migration. No hybrid. Pure Flutter.
2. **Signals-first state.** Minimal boilerplate, fine-grained rebuilds.
3. **Syncfusion DataGrid for tables.** Best Flutter table solution for financial data.
4. **flutter_quill for notes.** Rich text editing for research.
5. **go_router for routing.** Deep linking, nested routes, URL sync.
6. **Feature-first structure.** Each workspace is a feature module.
7. **Desktop-first.** Responsive layout via `LayoutBuilder`.
8. **WASM compilation.** Maximum performance on web.
