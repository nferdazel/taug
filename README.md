# Taug — Financial Research Platform

An investment research workspace built with Flutter Web (WASM). Combines auditable financial data foundations with a compact terminal-style UI for company research, screening, and valuation analysis.

## Features

### Research

- **Company Research** — Summary, financial metrics, statement history, data quality, research notes, and investment theses per company
- **Screener** — Sortable metric table with quality indicators across 19 seeded financial metrics
- **Valuation Snapshot** — Per-company metric cards organized by category (valuation, profitability, leverage, cash flow)
- **Research Notes** — CRUD notes per company, RLS-protected
- **Investment Theses** — Thesis tracking with stance (bullish/bearish/neutral), RLS-protected

### Market Monitoring (Preserved from Terminal)

- **Terminal Brief** — Dense landing page with top impact headlines, movers, and macro snapshot
- **Watchlist** — Custom watchlists with price snapshots
- **Chart** — Line, Area, Candlestick, OHLC Bar chart types
- **Market Overview** — Top movers
- **Portfolio** — Holdings tracker with P&L calculation

### Context Feeds

- **News** — Aggregated RSS from CNBC, Reuters, MarketWatch, Antara
- **Policy Monitor** — Official Fed and SEC policy/regulatory feed
- **Economic Calendar** — Events with importance levels

### Platform

- **Auth** — Register/login with username + password
- **Settings** — Timezone, density mode, default exchange
- **Compact Design System** — 12px typography floor, 2px-grid spacing, Bloomberg-terminal density
- **12-Tab Layout** — Brief, Market, Company, Screener, Valuation, Watchlist, Portfolio, Chart, News, Policy, Calendar, Settings

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter Web (WASM) |
| Language | Dart SDK ^3.12.2 |
| State Management | `signals` |
| Routing | `go_router` |
| Charts | `syncfusion_flutter_charts` |
| Auth & DB | Supabase (schema: `taug`) |
| Fonts | IBM Plex Mono + IBM Plex Sans |
| Workers | Python (SEC data pipeline) |
| Scheduling | GitHub Actions |
| Hosting | Vercel |

## Architecture

Feature-First Clean Architecture:

```
lib/
├── core/          # Config, theme, errors, network, schema, utils
├── features/      # Feature modules (15 features)
│   ├── auth/
│   ├── brief/
│   ├── calendar/
│   ├── chart/
│   ├── company/       # Research page: summary, metrics, statements, quality, notes, theses
│   ├── layout/        # Tabbed navigation shell
│   ├── market/
│   ├── news/
│   ├── policy/
│   ├── portfolio/
│   ├── screener/      # Sortable metric table with quality indicators
│   ├── settings/
│   ├── valuation/     # Per-company metric cards
│   └── watchlist/
├── shared/
│   ├── models/        # Exchange, Symbol, PriceData, NewsArticle, EconEvent, etc.
│   └── widgets/       # PriceCell, ChangeCell, VolumeCell, DataStatusBadge
└── main.dart
```

Each feature follows:
```
feature/
├── data/          # Repositories, API calls
├── domain/        # Entities, business logic
└── presentation/  # Pages, providers, widgets
```

### Data Pipeline

```
External Source → Worker Fetch → Raw Immutable Store → Validation → Normalization → Derived Metrics → Serving Views → Flutter
```

- **8 serving views** for Flutter-safe reads (company summary, statement history, filing timeline, metrics, quality, screener)
- **30 tables** across 5 layers (raw, normalized, filing/statement, derived/screener, research workspace)
- **9 views** for serving read models

### Workers (`workers/taug_worker/`)

6 worker jobs for the SEC data pipeline:

| Job | Purpose |
|---|---|
| `sync-sec-submissions` | Fetch SEC EDGAR submissions, normalize filings |
| `fetch-sec-filing-documents` | Store immutable raw filing documents |
| `sync-sec-companyfacts` | Ingest XBRL companyfacts payload |
| `parse-sec-companyfacts` | Parse into financial statements (35 XBRL concepts) |
| `compute-company-metrics` | Compute 19 financial metrics (TTM, balance sheet, price-dependent) |
| `sync-price-snapshots` | Fetch quotes from Twelve Data API |

## Data Sources

| Source | Data | Role |
|---|---|---|
| SEC EDGAR | Filings, XBRL facts, company data | Foundation |
| Twelve Data API | US/Global stock quotes | Supporting |
| Binance WebSocket | Crypto real-time | Supporting |
| RSS Feeds | News, policy feeds | Context |
| FRED (planned) | Macro time series | Foundation |
| Bank Indonesia (planned) | Rates, FX, macro | Foundation |

## Getting Started

### Prerequisites
- Flutter SDK ^3.12.2
- Supabase project
- Twelve Data API key (free)

### Setup

1. Clone the repository:
```bash
git clone <repo-url>
cd taug
```

2. Create `.env` file:
```bash
cp .env.example .env
# Edit .env with your keys
```

3. Install dependencies:
```bash
flutter pub get
```

4. Generate envied bindings:
```bash
dart run build_runner build
```

5. Run the app:
```bash
flutter run -d chrome
```

### Supabase Setup

1. Create a new schema `taug` in your Supabase project
2. Run the migration SQL files in `supabase/migrations/` in order
3. Expose the `taug` schema in Supabase Dashboard → Settings → API → Exposed schemas
4. Disable email confirmation: Authentication → Providers → Email → Disable "Confirm email"
5. Deploy Edge Functions:
```bash
supabase functions deploy get-price
supabase functions deploy get-chart-data
supabase functions deploy search-symbols
supabase functions deploy refresh-quote-snapshots
supabase functions deploy refresh-news
supabase functions deploy refresh-policy
```

6. Set Edge Function secrets:
```bash
supabase secrets set TWELVE_DATA_API_KEY=<your-key>
```

### SEC Worker Setup

The SEC data pipeline runs as scheduled GitHub Actions jobs:

| Workflow | Schedule | Command |
|---|---|---|
| `sec-submissions-sync.yml` | Daily 2:15am UTC | `sync-sec-submissions` |
| `sec-companyfacts-sync-parse.yml` | Daily 2:30am UTC | `sync-sec-companyfacts` then `parse-sec-companyfacts` |
| `sec-filing-documents-sync.yml` | Daily 2:45am UTC | `fetch-sec-filing-documents` |
| `recompute-metrics.yml` | Manual | `compute-company-metrics` |
| `sync-price-snapshots.yml` | Weekdays 2pm UTC | `sync-price-snapshots` |

Required GitHub secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SEC_USER_AGENT` (format: `YOUR_NAME YOUR_EMAIL@example.com`)
- `TWELVE_DATA_API_KEY`

Recommended GitHub variables:

- `SEC_TARGET_CIKS` — starter value: `0000320193,0000789019`
- `RAW_DOCUMENTS_BUCKET` — starter value: `raw-documents`

### Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service-role key for batch workers |
| `TWELVE_DATA_API_KEY` | Twelve Data API key (free tier) |
| `SEC_USER_AGENT` | SEC-compliant user agent string for EDGAR requests |
| `SEC_TARGET_CIKS` | Default comma-separated SEC CIK list for worker runs |
| `RAW_DOCUMENTS_BUCKET` | Supabase Storage bucket for raw filing documents |

## Project Structure

```
taug/
├── lib/                        # Dart source code (Flutter)
├── supabase/
│   ├── functions/              # Edge Functions (Deno)
│   ├── migrations/             # SQL migration files (18 migrations)
│   └── schema.sql              # Base schema definition
├── workers/
│   └── taug_worker/            # Python SEC data pipeline
│       ├── cli.py              # CLI entry point
│       ├── jobs/               # Worker jobs (6 jobs)
│       ├── sources/            # SEC EDGAR client
│       └── validators/         # Data validation
├── docs/                       # Architecture and planning docs (12 docs)
├── .github/workflows/          # CI/CD + scheduled data pipelines (6 workflows)
├── .env.example                # Environment template
├── AGENTS.md                   # AI guardrails
├── pubspec.yaml                # Dependencies
└── vercel.json                 # Vercel config (CSP, rewrites, caching)
```

## Deployment

### Flutter Web (Vercel)

Push to `main` branch triggers GitHub Actions:
1. Lint (`flutter analyze`)
2. Test (`flutter test`)
3. Build (`flutter build web --release`)
4. Deploy to Vercel

### Workers (GitHub Actions)

Scheduled workflows run the SEC data pipeline automatically. Manual triggers available for metrics recompute.

## Development

### Code Style
- Strong typing (NO `dynamic`)
- `Result<T>` pattern for error handling
- `signals` for state management
- `debugPrint` logging in catch blocks
- `RepaintBoundary` on high-frequency widgets

### Git Commits
Format: `<type>(<scope>): <description>`
```
feat(company): add company research page with metrics and statements
fix(watchlist): parallelize price fetching with Future.wait
docs(core): sync execution checklist with current state
```

### Adding a New Feature
1. Create directory structure: `lib/features/<name>/{data,domain,presentation}`
2. Create repository in `data/`
3. Create provider in `presentation/providers/`
4. Create page in `presentation/pages/`
5. Add route to `lib/core/config/app_router.dart`
6. Add tab to `lib/features/layout/presentation/pages/main_layout.dart`
7. Update `docs/research-platform-execution-checklist.md` before committing

## Planning Docs

- [AI Handoff Status](docs/ai-handoff-status.md)
- [Research Platform Pivot Audit](docs/research-platform-pivot-audit.md)
- [Research Platform Gap Analysis](docs/research-platform-gap-analysis.md)
- [Research Platform Execution Checklist](docs/research-platform-execution-checklist.md)
- [Research Platform Schema V2](docs/research-platform-schema-v2.md)
- [Research Platform Schema Implementation Plan](docs/research-platform-schema-implementation-plan.md)
- [Research Platform Ingestion Topology](docs/research-platform-ingestion-topology.md)
- [Research Platform Screener and Metric Engine Design](docs/research-platform-screener-metric-engine.md)
- [Research Platform Source Strategy](docs/research-platform-source-strategy.md)
- [SEC Filings Foundation Checklist](docs/sec-filings-foundation-checklist.md)

## License

Private — All rights reserved.
