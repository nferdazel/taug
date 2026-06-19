# Taug — Financial Terminal

A high-performance financial terminal built with Flutter Web (WASM), designed for real-time market data, portfolio tracking, and financial analysis.

## Features

### Market Data
- **Terminal Brief** — Dense landing page with top impact headlines, movers, and macro snapshot
- **Watchlist** — Custom watchlists with real-time price updates (auto-refresh every 5s)
- **Chart** — 4 chart types with `Line` as default: Line, Area, Candlestick, OHLC Bar
- **Order Book** — 10-level ask/bid depth with spread indicator
- **Running Trades** — Time & sales feed
- **Market Overview** — Top movers with auto-refresh

### Portfolio
- **Holdings Tracker** — Add/edit/remove holdings with quantity & avg price
- **P&L Calculation** — Real-time profit/loss with percentage
- **Total Value** — Aggregated portfolio value

### News & Calendar
- **RSS News Feed** — Aggregated from CNBC, Reuters, MarketWatch, Antara
- **Policy Monitor** — Official Fed and SEC policy/regulatory feed
- **Economic Calendar** — Events with importance levels (High/Medium/Low)
- **Category Filters** — Markets, Economy, Geopolitics, Earnings
- **Top Impact Ranking** — Ranked headlines combining news and policy relevance

### Platform
- **Auth** — Register/login with username + password
- **Settings** — Timezone selection, density mode
- **Terminal UI Baseline** — 12px typography floor with compact 2px-grid sizing
- **9-Tab Layout** — Brief, Market, Watchlist, Portfolio, Chart, News, Policy, Calendar, Settings

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
| Hosting | Vercel |
| CI/CD | GitHub Actions |

## Architecture

Feature-First Clean Architecture:

```
lib/
├── core/          # Config, theme, errors, network, utils
├── features/      # Feature modules (auth, brief, watchlist, chart, news, policy, calendar, market, portfolio, settings)
├── shared/        # Models and reusable widgets
└── main.dart      # Entry point
```

Each feature follows:
```
feature/
├── data/          # Repositories, API calls
├── domain/        # Entities, business logic
└── presentation/  # Pages, providers, widgets
```

## Data Sources

| Source | Data | Cost |
|---|---|---|
| Twelve Data API | US/Global stocks, commodities | Free tier |
| Binance WebSocket | Crypto real-time | Free |
| RSS Feeds | News aggregation | Free |
| SEC / FRED / BLS / Official feeds | Filings and macro/public data | Free/public |

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
2. Run the migration SQL files in `supabase/migrations/`
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
supabase functions deploy refresh-calendar
```

6. Set Edge Function secrets:
```bash
supabase secrets set TWELVE_DATA_API_KEY=<your-key>
```

### Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |
| `TWELVE_DATA_API_KEY` | Twelve Data API key (free tier) |

## Project Structure

```
taug/
├── lib/                    # Dart source code
├── supabase/
│   ├── functions/          # Edge Functions (Deno)
│   └── migrations/         # SQL migration files
├── .env.example            # Environment template
├── AGENTS.md               # AI guardrails
├── pubspec.yaml            # Dependencies
└── vercel.json             # Vercel config
```

## Deployment

Push to `main` branch triggers GitHub Actions:
1. Lint (`flutter analyze`)
2. Test (`flutter test`)
3. Build (`flutter build web --release`)
4. Deploy to Vercel

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
feat(chart): add line, area, and OHLC chart types
fix(watchlist): parallelize price fetching with Future.wait
style(settings): redesign to compact desktop layout
```

### Adding a New Feature
1. Create directory structure: `lib/features/<name>/{data,domain,presentation}`
2. Create repository in `data/`
3. Create provider in `presentation/providers/`
4. Create page in `presentation/pages/`
5. Add route to `lib/core/config/app_router.dart`
6. Add tab to `lib/features/layout/presentation/pages/main_layout.dart`

## License

Private — All rights reserved.
