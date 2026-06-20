# C5 — Foundation Implementation Plan

**Date:** 2026-06-20
**Type:** Implementation blueprint — no code
**Perspective:** Senior Flutter Engineer + Design System Engineer + Flutter Web Specialist

---

## Executive Summary

Foundation is everything that exists before business features. It creates the app shell, navigation, theme, design primitives, and reusable components. After Foundation, Company Workspace implementation can begin immediately with no infrastructure gaps.

**Foundation deliverable:** A working Flutter Web app with navigation, theme, and reusable components — but no business logic.

---

## Foundation Scope

### In Scope (Foundation)

| Component | Purpose |
|---|---|
| App Shell | Global layout, workspace container |
| Navigation | 5-tab desktop navigation |
| Theme | Material 3 dark theme, IBM Plex fonts |
| Design Primitives | Buttons, cards, badges, chips, sections |
| Status Components | Quality badge, freshness badge, conviction badge |
| Table Foundation | Base table abstraction for financial data |
| Responsive Strategy | Breakpoints, collapse behavior |
| Empty States | Reusable empty state components |
| Loading States | Skeleton loaders, progress indicators |
| Error States | Error display components |

### Out of Scope (Business Features)

| Component | Phase |
|---|---|
| Company list | Phase 1 |
| Company workspace | Phase 1 |
| Research notes | Phase 2 |
| Portfolio | Phase 3 |
| Screener | Post-MVP |
| Comparison | Post-MVP |

---

## App Shell

### Structure

```
App
└── MaterialApp.router (go_router)
    └── MainLayout
        ├── NavigationBar (40px, fixed top)
        └── Content Area (expanded)
            └── Workspace Page (router outlet)
```

### Widget Hierarchy

```dart
class MainLayout extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          NavigationBar(),          // 40px fixed
          Expanded(child: child),   // Router outlet
        ],
      ),
    );
  }
}
```

### Responsibilities

| Component | Responsibility |
|---|---|
| `MainLayout` | Global shell, contains navigation + content |
| `NavigationBar` | Tab switching, brand display |
| Content Area | Renders workspace pages via go_router |
| Workspace Page | Each page owns its layout |

---

## Navigation System

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────┐
│ TAUG   Companies  Research  Portfolio  Data  Settings       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    [Workspace Content]                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Implementation

```dart
class NavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildLogo(),
          const VerticalDivider(width: 1),
          Expanded(child: _buildTabs()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _TabItem(icon: Icons.business, label: 'Companies', path: '/companies'),
        _TabItem(icon: Icons.edit_note, label: 'Research', path: '/research'),
        _TabItem(icon: Icons.account_balance_wallet, label: 'Portfolio', path: '/portfolio'),
        _TabItem(icon: Icons.storage, label: 'Data', path: '/data'),
        _TabItem(icon: Icons.settings, label: 'Settings', path: '/settings'),
      ],
    );
  }
}
```

### Tab Behavior

| Behavior | Implementation |
|---|---|
| Active state | Accent color underline + bold label |
| Hover state | Background highlight |
| Keyboard | 1-5 for tab switching |
| Click | `context.go(path)` |

---

## Theme Strategy

### Material 3 Dark Theme

```dart
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.accent,        // #3b82f6
    surface: AppColors.surface,       // #18181b
    onSurface: AppColors.textPrimary, // #fafafa
    outline: AppColors.border,        // #27272a
  ),
  scaffoldBackgroundColor: AppColors.background, // #09090b
  fontFamily: 'IBM Plex Sans',
  textTheme: _buildTextTheme(),
);
```

### Typography

```dart
TextTheme _buildTextTheme() {
  return TextTheme(
    headlineLarge: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 24, fontWeight: w600),
    headlineMedium: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 20, fontWeight: w600),
    headlineSmall: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 16, fontWeight: w600),
    bodyLarge: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14, fontWeight: w400),
    bodyMedium: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 13, fontWeight: w400),
    bodySmall: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 12, fontWeight: w400),
    labelLarge: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 14, fontWeight: w500),
    labelMedium: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 12, fontWeight: w500),
    labelSmall: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10, fontWeight: w500),
  );
}
```

### Spacing Scale

```dart
abstract class AppSpacing {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double xxxl = 32;
}
```

### Radius Scale

```dart
abstract class AppRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double full = 999;
}
```

---

## Design System Primitives

### MVP Primitives

| Component | Purpose | Variants |
|---|---|---|
| `AppButton` | Actions | primary, secondary, ghost, danger |
| `AppCard` | Containers | default, outlined, interactive |
| `AppBadge` | Status indicators | default, dot |
| `AppChip` | Tags, labels | default, selected |
| `AppSectionHeader` | Section titles | default, with action |
| `AppWorkspaceHeader` | Page headers | title + subtitle + actions |
| `AppEmptyState` | Empty content | icon + title + description + action |
| `AppLoadingState` | Loading indicator | spinner, skeleton |
| `AppErrorState` | Error display | message + retry |
| `AppDivider` | Separators | default, with label |
| `AppTooltip` | Hover info | default |

### Component API Examples

```dart
// Button
AppButton(
  label: 'New Note',
  icon: Icons.add,
  onPressed: () {},
  variant: AppButtonVariant.primary,
)

// Card
AppCard(
  child: Column(children: [...]),
  onTap: () {},
)

// Badge
AppBadge(
  label: 'Fresh',
  color: AppColors.success,
  icon: Icons.circle,
)

// Section Header
AppSectionHeader(
  title: 'Key Metrics',
  action: AppButton(label: 'View All', variant: AppButtonVariant.ghost),
)

// Empty State
AppEmptyState(
  icon: Icons.note_add,
  title: 'No notes yet',
  description: 'Start researching companies to create notes.',
  action: AppButton(label: 'Browse Companies', onPressed: () {}),
)
```

---

## Status Components

### Quality Badge

```dart
class QualityBadge extends StatelessWidget {
  final double score; // 0.0 - 1.0

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: '${(score * 100).round()}%',
      color: _scoreColor(score),
      icon: Icons.circle,
      size: AppBadgeSize.small,
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }
}
```

### Freshness Badge

```dart
class FreshnessBadge extends StatelessWidget {
  final FreshnessStatus status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label,
      color: status.color,
      icon: Icons.circle,
      size: AppBadgeSize.small,
    );
  }
}

enum FreshnessStatus {
  fresh(label: 'Fresh', color: AppColors.success),
  aging(label: 'Aging', color: AppColors.warning),
  stale(label: 'Stale', color: AppColors.error),
  expired(label: 'Expired', color: AppColors.textTertiary),
  unknown(label: '—', color: AppColors.textTertiary);
}
```

### Conviction Badge

```dart
class ConvictionBadge extends StatelessWidget {
  final ConvictionLevel level;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: level.label,
      color: level.color,
      icon: Icons.circle,
    );
  }
}

enum ConvictionLevel {
  low(label: 'Low', color: AppColors.warning),
  medium(label: 'Medium', color: AppColors.accent),
  high(label: 'High', color: AppColors.success);
}
```

---

## Table Foundation

### Base Table Abstraction

```dart
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final bool sortable;
  final int? frozenColumns;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        columns: columns.map((c) => DataColumn(
          label: Text(c.label, style: AppTypography.monoLabel),
          numeric: c.numeric,
          onSort: sortable ? c.onSort : null,
        )).toList(),
        rows: rows.map((r) => DataRow(
          cells: r.cells.map((c) => DataCell(
            c.widget ?? Text(c.value ?? '—', style: AppTypography.monoData),
          )).toList(),
        )).toList(),
      ),
    );
  }
}
```

### Column Model

```dart
class AppTableColumn {
  final String key;
  final String label;
  final bool numeric;
  final double? width;
  final void Function(int, bool)? onSort;

  const AppTableColumn({
    required this.key,
    required this.label,
    this.numeric = false,
    this.width,
    this.onSort,
  });
}
```

### Financial Table (for statements)

```dart
class FinancialStatementTable extends StatelessWidget {
  final List<FinancialStatementRow> rows;
  final List<String> periods;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      columns: [
        AppTableColumn(key: 'label', label: ''),
        ...periods.map((p) => AppTableColumn(
          key: p, label: p, numeric: true,
        )),
      ],
      rows: rows.map((r) => AppTableRow(
        cells: [
          AppTableCell(value: r.label),
          ...r.values.map((v) => AppTableCell(
            value: v != null ? _formatFinancial(v) : '—',
          )),
        ],
      )).toList(),
    );
  }
}
```

---

## Responsive Strategy

### Breakpoints

```dart
abstract class AppBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1280;
  static const double wide = 1440;
}
```

### Layout Behavior

| Screen Size | Behavior |
|---|---|
| ≥1440px | Full layout, wide content area |
| ≥1280px | Full layout, standard content area |
| ≥1024px | Compact layout, smaller sidebar |
| ≥768px | Tablet: sidebar collapses to icons |
| <768px | Mobile: bottom navigation (future) |

### Implementation

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktop) {
          return _desktopLayout(child);
        } else if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return _tabletLayout(child);
        } else {
          return _mobileLayout(child);
        }
      },
    );
  }
}
```

---

## Empty States

### Standard Empty State

```dart
AppEmptyState(
  icon: Icons.note_add_outlined,
  title: 'No notes yet',
  description: 'Start researching companies to create notes.',
  action: AppButton(
    label: 'Browse Companies',
    onPressed: () => context.go('/companies'),
    variant: AppButtonVariant.primary,
  ),
)
```

### Empty State Inventory

| Context | Icon | Title | Description |
|---|---|---|---|
| No notes | `note_add` | No notes yet | Start researching companies to create notes. |
| No theses | `lightbulb` | No theses yet | Create your first investment thesis. |
| No portfolio | `account_balance_wallet` | Start building your portfolio | Track your investment decisions. |
| No research queue | `queue` | Research queue is empty | Add companies from the company list. |
| No companies | `business` | No companies available | Check back after data sync. |

---

## Loading & Error States

### Loading States

```dart
// Spinner
AppLoadingState(message: 'Loading companies...')

// Skeleton
AppSkeleton(height: 16, width: 120)
AppSkeleton(height: 28, width: double.infinity)
```

### Error States

```dart
AppErrorState(
  message: 'Failed to load data',
  onRetry: () => refetch(),
)
```

### Error Handling Pattern

```dart
class AsyncBuilder<T> extends StatelessWidget {
  final AsyncSignal<T> signal;
  final Widget Function(T data) builder;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    return Watcher((context) {
      if (signal.isLoading) return AppLoadingState();
      if (signal.hasError) return AppErrorState(message: signal.error.toString());
      if (signal.value == null || signal.valueIsEmpty) return emptyState ?? AppEmptyState();
      return builder(signal.value);
    });
  }
}
```

---

## Build Order

### Step 1: Theme & Design Tokens (Day 1)

```
lib/core/theme/
├── app_theme.dart          # Material 3 dark theme
├── app_colors.dart         # Color palette
├── app_typography.dart     # IBM Plex font scale
├── app_spacing.dart        # Spacing tokens
└── app_radius.dart         # Radius tokens
```

### Step 2: Design Primitives (Day 2-3)

```
lib/shared/widgets/
├── app_button.dart
├── app_card.dart
├── app_badge.dart
├── app_chip.dart
├── app_section_header.dart
├── app_empty_state.dart
├── app_loading_state.dart
├── app_error_state.dart
└── app_divider.dart
```

### Step 3: Status Components (Day 3)

```
lib/shared/widgets/
├── quality_badge.dart
├── freshness_badge.dart
└── conviction_badge.dart
```

### Step 4: Table Foundation (Day 4)

```
lib/shared/widgets/
├── app_table.dart
├── app_table_column.dart
├── app_table_row.dart
└── financial_statement_table.dart
```

### Step 5: App Shell + Navigation (Day 5-6)

```
lib/features/layout/
└── presentation/
    ├── main_layout.dart
    └── navigation_bar.dart

lib/core/config/
└── app_router.dart         # go_router with 5 workspace routes
```

### Step 6: Workspace Container (Day 6)

```
lib/shared/widgets/
├── workspace_header.dart
├── workspace_tabs.dart
└── workspace_content.dart
```

### Step 7: Empty/Loading/Error States (Day 7)

```
lib/shared/widgets/
├── async_builder.dart
├── skeleton_loader.dart
└── error_display.dart
```

### Total: ~7 focused days

---

## Done Criteria

Foundation is complete when:

| Criterion | Verification |
|---|---|
| App shell renders | `flutter run -d chrome` shows navigation + content area |
| 5 tabs navigate | Click each tab → correct page renders |
| Theme applies | Dark theme, IBM Plex fonts, correct colors |
| Primitives work | Buttons, cards, badges render correctly |
| Status badges work | Quality, freshness, conviction badges display |
| Table renders | Financial statement table displays data |
| Empty states work | Empty state shows when no data |
| Loading states work | Skeleton loader shows during fetch |
| Error states work | Error display shows on failure |
| Responsive layout | Adapts to 1440/1280/1024/768 breakpoints |
| Deep linking works | `/companies/aapl/financials` navigates correctly |

After Foundation: Company Workspace implementation begins immediately.

---

## Recommendation

1. **Theme first.** Everything depends on colors, fonts, spacing.
2. **Primitives second.** All pages use buttons, cards, badges.
3. **Shell third.** Navigation and layout wrap everything.
4. **Tables fourth.** Financial tables are the most complex primitive.
5. **States fifth.** Empty/loading/error are needed by every page.
6. **7 focused days.** Realistic for a senior Flutter developer.
7. **Test each step.** Verify in browser before moving on.
