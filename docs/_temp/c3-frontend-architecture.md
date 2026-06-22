# C3 — Frontend Architecture

**Date:** 2026-06-20
**Type:** Technical architecture — no implementation
**Perspective:** Frontend Architect + Staff Engineer + Product Engineer

---

## Executive Summary

TAUG's frontend should use **React + TypeScript** for the new research platform, replacing the existing Flutter Web shell for research-specific pages. The existing Flutter terminal features (watchlist, portfolio, chart) can coexist via iframe or gradual migration. React provides the best ecosystem for data-heavy table rendering, research note editing, and trust component development.

**Key decision:** React over Flutter for new research pages. Rationale: table rendering, rich text editing, and component ecosystem maturity.

---

## Recommended Stack

### Core Stack

| Layer | Technology | Rationale |
|---|---|---|
| Framework | React 19 | Component ecosystem, community, hiring |
| Language | TypeScript 5 | Type safety, developer experience |
| Build | Vite | Fast dev server, modern bundling |
| Routing | React Router 7 | Declarative, file-based optional |
| State | Zustand + TanStack Query | Simple global state + server state |
| Tables | TanStack Table | Sorting, filtering, pagination, virtualization |
| Styling | Tailwind CSS 4 | Utility-first, fast prototyping |
| Components | Radix UI | Accessible primitives, headless |
| Rich Text | Tiptap | Research notes, theses |
| Charts | Recharts | Simple, composable |
| Forms | React Hook Form | Performant, minimal re-renders |
| Validation | Zod | Schema validation |

### Why React Over Alternatives

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| React | Ecosystem, community, hiring, tables | Bundle size, complexity | ✅ Recommended |
| Vue | Simpler, good DX | Smaller ecosystem for financial tables | ❌ |
| Svelte | Fast, simple | Small ecosystem, limited table options | ❌ |
| Flutter (existing) | Already exists, WASM | Poor table rendering, no rich text, limited web ecosystem | ❌ for research |
| Solid | Performant | Too small ecosystem | ❌ |

### Why Not Continue Flutter

The existing Flutter Web shell works for terminal features but is wrong for research:
- **Tables:** Flutter tables are basic. TanStack Table is superior.
- **Rich text:** Flutter has no mature rich text editor. Tiptap is excellent.
- **Component ecosystem:** React's ecosystem for data-heavy UIs is 10x larger.
- **Developer experience:** React + TypeScript + Vite is faster iteration than Flutter Web.

**Migration strategy:** Existing Flutter features (watchlist, portfolio, chart) remain. New research features built in React. Gradual migration over time.

---

## Application Architecture

### High-Level Structure

```
┌─────────────────────────────────────────────────────────┐
│                    Application Shell                      │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Navigation (React)                                   │ │
│  ├─────────────────────────────────────────────────────┤ │
│  │ Workspace Router                                     │ │
│  │  ┌───────┬───────┬───────┬───────┬───────┬───────┐ │ │
│  │  │Dash-  │Compa- │Scre-  │Re-    │Port-  │Data   │ │ │
│  │  │board  │nies   │ener   │search │folio  │       │ │ │
│  │  └───────┴───────┴───────┴───────┴───────┴───────┘ │ │
│  ├─────────────────────────────────────────────────────┤ │
│  │ Data Layer (Supabase + TanStack Query)               │ │
│  ├─────────────────────────────────────────────────────┤ │
│  │ Trust Layer (Freshness + Quality + Sources)          │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure

```
src/
├── app/
│   ├── layout/           # Global shell, navigation
│   ├── routes/           # Route definitions
│   └── providers/        # Global providers
├── features/
│   ├── companies/        # Company workspace
│   ├── screener/         # Screener workspace
│   ├── research/         # Research workspace
│   ├── portfolio/        # Portfolio workspace
│   ├── comparison/       # Comparison workspace
│   ├── data/             # Data workspace
│   └── settings/         # Settings
├── shared/
│   ├── components/       # Reusable components
│   ├── hooks/            # Custom hooks
│   ├── lib/              # Utilities
│   └── types/            # Shared types
├── data/
│   ├── supabase/         # Supabase client
│   ├── queries/          # TanStack Query definitions
│   └── mutations/        # Write operations
└── styles/               # Tailwind config, global styles
```

---

## Routing Architecture

### URL Structure

```
/                           → Dashboard
/companies                  → Company list
/companies/:id              → Company workspace
/companies/:id/overview     → Company overview tab
/companies/:id/financials   → Company financials tab
/companies/:id/valuation    → Company valuation tab
/companies/:id/research     → Company research tab
/companies/:id/data         → Company data tab
/screener                   → Screener workspace
/research                   → Research workspace
/research/notes             → Notes list
/research/theses            → Theses list
/research/watchlists        → Watchlists
/compare                    → Comparison workspace
/compare/:idA/:idB          → Specific comparison
/portfolio                  → Portfolio workspace
/data                       → Data workspace
/settings                   → Settings
```

### Route Configuration

```typescript
const routes = [
  { path: '/', element: <Dashboard /> },
  { path: '/companies', element: <CompanyList /> },
  { path: '/companies/:id', element: <CompanyWorkspace />, children: [
    { path: 'overview', element: <CompanyOverview /> },
    { path: 'financials', element: <CompanyFinancials /> },
    { path: 'valuation', element: <CompanyValuation /> },
    { path: 'research', element: <CompanyResearch /> },
    { path: 'data', element: <CompanyData /> },
  ]},
  { path: '/screener', element: <ScreenerWorkspace /> },
  { path: '/research', element: <ResearchWorkspace /> },
  { path: '/compare/:idA/:idB', element: <ComparisonWorkspace /> },
  { path: '/portfolio', element: <PortfolioWorkspace /> },
  { path: '/data', element: <DataWorkspace /> },
  { path: '/settings', element: <Settings /> },
];
```

---

## State Management

### State Categories

| Category | Tool | Scope | Example |
|---|---|---|---|
| Server state | TanStack Query | Remote data | Companies, metrics, notes |
| Global UI | Zustand | App-wide | Active company, theme |
| Workspace UI | Zustand (scoped) | Per-workspace | Screener filters, sort |
| Form state | React Hook Form | Per-form | Note editor, thesis editor |
| Transient | useState | Per-component | Hover state, modal open |

### Server State (TanStack Query)

```typescript
// Query keys
const queryKeys = {
  companies: ['companies'] as const,
  company: (id: string) => ['companies', id] as const,
  companyMetrics: (id: string) => ['companies', id, 'metrics'] as const,
  companyFinancials: (id: string) => ['companies', id, 'financials'] as const,
  screener: (filters: ScreenerFilters) => ['screener', filters] as const,
  notes: (companyId?: string) => ['notes', companyId] as const,
  theses: (companyId?: string) => ['theses', companyId] as const,
  portfolio: ['portfolio'] as const,
  freshness: (companyId: string) => ['freshness', companyId] as const,
  quality: (companyId: string) => ['quality', companyId] as const,
};

// Example query
function useCompanyMetrics(companyId: string) {
  return useQuery({
    queryKey: queryKeys.companyMetrics(companyId),
    queryFn: () => fetchCompanyMetrics(companyId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}
```

### Global State (Zustand)

```typescript
interface AppState {
  activeCompanyId: string | null;
  setActiveCompanyId: (id: string | null) => void;
  theme: 'dark' | 'light';
  setTheme: (theme: 'dark' | 'light') => void;
}

const useAppStore = create<AppState>((set) => ({
  activeCompanyId: null,
  setActiveCompanyId: (id) => set({ activeCompanyId: id }),
  theme: 'dark',
  setTheme: (theme) => set({ theme }),
}));
```

---

## Data Fetching Strategy

### Supabase Client

```typescript
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
  { db: { schema: 'taug' } }
);
```

### Query Patterns

| Data | Pattern | Cache | Refresh |
|---|---|---|---|
| Company list | `useQuery` | 10 min | On focus |
| Company detail | `useQuery` | 5 min | On focus |
| Metrics | `useQuery` | 5 min | On focus |
| Financials | `useQuery` | 10 min | On focus |
| Notes/Theses | `useQuery` | 1 min | On mutation |
| Portfolio | `useQuery` | 2 min | On mutation |
| Freshness | `useQuery` | 5 min | On focus |
| Quality | `useQuery` | 5 min | On focus |

### Mutation Patterns

```typescript
// Create note
function useCreateNote() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (note: CreateNoteInput) => createNote(note),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.notes() });
    },
  });
}
```

---

## Component Architecture

### Component Hierarchy

```
App
├── Shell
│   ├── Navigation
│   └── Content Area
├── Workspace (per page)
│   ├── WorkspaceHeader
│   ├── WorkspaceTabs
│   └── WorkspaceContent
├── Cards
│   ├── CompanyCard
│   ├── MetricCard
│   ├── ResearchCard
│   ├── ThesisCard
│   └── AlertCard
├── Tables
│   ├── DataTable (TanStack Table wrapper)
│   ├── MetricTable
│   ├── ComparisonTable
│   └── ScreenerTable
├── Badges
│   ├── FreshnessBadge
│   ├── QualityBadge
│   ├── ConvictionBadge
│   ├── SourceBadge
│   └── SectorBadge
├── Trust
│   ├── TrustIndicator
│   ├── SourceDisplay
│   ├── FreshnessDisplay
│   └── QualityDisplay
└── Research
    ├── NoteEditor
    ├── ThesisEditor
    ├── ConvictionSelector
    └── DecisionJournal
```

### Component Patterns

**Compound Components** for complex UI:
```typescript
<CompanyWorkspace>
  <CompanyWorkspace.Header company={company} />
  <CompanyWorkspace.Tabs>
    <CompanyWorkspace.Tab name="overview">...</CompanyWorkspace.Tab>
    <CompanyWorkspace.Tab name="financials">...</CompanyWorkspace.Tab>
  </CompanyWorkspace.Tabs>
</CompanyWorkspace>
```

**Render Props** for data-dependent UI:
```typescript
<CompanyMetrics companyId={id}>
  {({ metrics, isLoading, error }) => (
    isLoading ? <Skeleton /> : <MetricGrid metrics={metrics} />
  )}
</CompanyMetrics>
```

---

## Table Architecture

### TanStack Table Configuration

```typescript
const columns = [
  { accessorKey: 'display_name', header: 'Company', size: 200 },
  { accessorKey: 'pe', header: 'PE', size: 80, cell: ({ getValue }) => (
    <MetricCell value={getValue()} format="ratio" />
  )},
  { accessorKey: 'roe', header: 'ROE', size: 80, cell: ({ getValue }) => (
    <MetricCell value={getValue()} format="percentage" />
  )},
  { accessorKey: 'quality_score', header: 'Quality', size: 100, cell: ({ getValue }) => (
    <QualityBadge score={getValue()} />
  )},
  { accessorKey: 'freshness', header: 'Fresh', size: 80, cell: ({ getValue }) => (
    <FreshnessBadge status={getValue()} />
  )},
];
```

### Table Features

| Feature | Implementation |
|---|---|
| Sorting | TanStack Table built-in |
| Filtering | TanStack Table + custom filter panel |
| Pagination | TanStack Table built-in |
| Column visibility | TanStack Table built-in |
| Virtualization | TanStack Virtual for large datasets |
| Comparison | Custom column groups |
| Export | CSV/Excel generation |

### Financial Statement Table

```typescript
// Income statement table with period columns
const statementColumns = [
  { accessorKey: 'line_item', header: '', size: 200 },
  { accessorKey: 'fy2025', header: 'FY2025', size: 100, cell: FinancialCell },
  { accessorKey: 'fy2024', header: 'FY2024', size: 100, cell: FinancialCell },
  { accessorKey: 'fy2023', header: 'FY2023', size: 100, cell: FinancialCell },
];
```

---

## Research Architecture

### Note Editor (Tiptap)

```typescript
<NoteEditor
  companyId={companyId}
  initialContent={note.content}
  tags={note.tags}
  onSave={(content, tags) => updateNote({ content, tags })}
/>
```

### Thesis Editor

```typescript
<ThesisEditor
  companyId={companyId}
  initialThesis={thesis}
  onSave={(thesis) => updateThesis(thesis)}
  sections={['summary', 'bullCase', 'bearCase', 'assumptions', 'catalysts', 'risks', 'exitConditions']}
/>
```

### Conviction Selector

```typescript
<ConvictionSelector
  value={position.conviction}
  onChange={(conviction, reason) => updateConviction({ conviction, reason })}
  options={['low', 'medium', 'high']}
/>
```

---

## Trust Layer Architecture

### Trust Data Flow

```
Supabase (freshness, quality, sources)
    ↓
TanStack Query (cached, stale-while-revalidate)
    ↓
Trust Components (badges, indicators)
    ↓
Workspace UI (embedded in company header, metric rows)
```

### Trust Hooks

```typescript
function useCompanyFreshness(companyId: string) {
  return useQuery({
    queryKey: queryKeys.freshness(companyId),
    queryFn: () => fetchCompanyFreshness(companyId),
    staleTime: 5 * 60 * 1000,
  });
}

function useCompanyQuality(companyId: string) {
  return useQuery({
    queryKey: queryKeys.quality(companyId),
    queryFn: () => fetchCompanyQuality(companyId),
    staleTime: 5 * 60 * 1000,
  });
}
```

### Trust Components

```typescript
// Freshness badge
<FreshnessBadge status="fresh" lastUpdated="2026-06-20" />

// Quality badge
<QualityBadge score={83} breakdown={{ coverage: 100, completeness: 85 }} />

// Source badge
<SourceBadge source="SEC EDGAR" official={true} />
```

---

## Performance Strategy

### Rendering Optimization

| Strategy | When | How |
|---|---|---|
| Memoization | Expensive computations | `useMemo`, `React.memo` |
| Virtualization | Large lists/tables | TanStack Virtual |
| Code splitting | Route-level | `React.lazy` |
| Image optimization | Company logos | Next/Image equivalent |
| Skeleton loading | Data fetching | Skeleton components |

### Caching Strategy

| Data | Cache Duration | Invalidation |
|---|---|---|
| Company list | 10 min | On focus |
| Financials | 10 min | On focus |
| Metrics | 5 min | On focus |
| Notes | 1 min | On mutation |
| Portfolio | 2 min | On mutation |
| Freshness | 5 min | On focus |

### Virtualization for Large Tables

```typescript
// TanStack Virtual for 1000+ row tables
const virtualizer = useVirtualizer({
  count: data.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 32,
  overscan: 10,
});
```

---

## Offline Strategy

### Decision: No Offline Support

**Rationale:**
- TAUG is a research platform, not a mobile app
- Data freshness is critical — stale offline data is harmful
- Supabase requires network for auth and queries
- Complexity cost outweighs benefit

**Exception:** Research notes could be cached locally for draft protection.

---

## MVP Architecture

### Must Have

| Component | Rationale |
|---|---|
| React + TypeScript + Vite | Core stack |
| Supabase client | Data access |
| TanStack Query | Server state |
| TanStack Table | Financial tables |
| Tailwind CSS | Styling |
| Company Workspace | Core research |
| Screener | Discovery |
| Research (notes + theses) | Workflow |
| Portfolio | Tracking |
| Settings | Configuration |

### Should Have

| Component | Rationale |
|---|---|
| Comparison Workspace | Decision support |
| Data Workspace | Trust transparency |
| Dashboard | Convenience |
| Tiptap editor | Rich notes |
| Recharts | Metric charts |

### Future

| Component | Rationale |
|---|---|
| Mobile adaptation | Reach |
| Offline support | Convenience |
| Real-time updates | Monitoring |
| Collaboration | Team research |

---

## Risks

### Migration Complexity

**Risk:** Flutter + React coexistence is complex.

**Mitigation:** Keep Flutter for existing features. Build new in React. Migrate gradually.

### Bundle Size

**Risk:** React + TanStack + Tiptap = large bundle.

**Mitigation:** Code splitting. Lazy load heavy components.

### Developer Experience

**Risk:** Two frameworks (Flutter + React) = two skill sets.

**Mitigation:** Long-term plan is full React migration. Flutter is legacy.

### Data Consistency

**Risk:** Flutter and React read same Supabase data differently.

**Mitigation:** Shared Supabase schema. Same queries. Same RLS.

---

## Recommendation

1. **React + TypeScript + Vite** for new research platform.
2. **TanStack Query + Zustand** for state management.
3. **TanStack Table** for all financial tables.
4. **Tailwind CSS** for styling.
5. **Keep Flutter** for existing terminal features. Migrate later.
6. **Desktop-first.** Mobile is future.
7. **Start with 5 workspaces.** Company, Screener, Research, Portfolio, Settings.
