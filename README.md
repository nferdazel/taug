# TAUG — Research Operating System

An investment research workspace for individual investors. TAUG helps users research companies, form investment theses, track decisions, and learn from outcomes.

## What TAUG Is

**Research Operating System** — Not a terminal, not a dashboard, not a screener.

Core workflow:
```
Discover → Research → Thesis → Decision → Portfolio → Outcome → Learning
```

## Features

### Research Workflow

- **Company Workspace** — Overview, Financials, Research tabs with data trust indicators
- **Research Questions** — Track open investigation threads with priority levels
- **Investment Theses** — 10-field structured theses (stance, conviction, bull/bear case, assumptions, catalysts, risks, exit conditions)
- **Research Notes** — CRUD notes linked to companies
- **Evidence Tracking** — Connect notes to thesis fields (supports, contradicts, updates, context)

### Decision Support

- **Thesis → Position Bridge** — Create positions directly from theses with auto-populated conviction
- **Portfolio Workspace** — Active/closed positions with P&L tracking
- **Lessons Learned** — Record outcomes and insights from each decision
- **Pattern Intelligence** — Stance accuracy, conviction accuracy, common lesson themes

### Data Trust

- **Quality Scores** — 7-component breakdown (historical coverage, completeness, validation, verification, freshness, restatement support)
- **Freshness Indicators** — Visual badges showing data age
- **Restatement Tracking** — Identify restated financial statements
- **Source Attribution** — Track data provenance

### Research Intelligence

- **Research Progress** — 4-step checklist (Notes → Thesis → Questions → Position)
- **Needs Attention** — Priority-sorted list of items needing action
- **Research Freshness** — Track when research was last reviewed
- **Invalidation Conditions** — Structured exit triggers (planned)

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter Web |
| Language | Dart SDK ^3.12.2 |
| State | `signals` |
| Routing | `go_router` |
| Database | Supabase (schema: `taug`) |
| Workers | Python (SEC data pipeline) |
| Hosting | Vercel |

## Architecture

```
lib/
├── core/          # Config, theme, errors, network, schema, utils
├── features/      # Feature modules
│   ├── auth/      # Authentication
│   ├── company/   # Company workspace (overview, financials, research)
│   ├── portfolio/ # Portfolio workspace (positions, lessons, patterns)
│   ├── research/  # Research workspace (questions, theses, notes)
│   ├── companies/ # Companies list
│   ├── settings/  # User settings
│   └── ...
├── shared/
│   ├── models/    # Shared data models
│   └── widgets/   # Reusable UI components
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK ^3.12.2
- Supabase project
- Python 3.12+ (for workers)

### Setup

1. Clone and configure:
```bash
git clone <repo-url>
cd taug
cp .env.example .env
# Edit .env with your keys
```

2. Install and run:
```bash
flutter pub get
dart run build_runner build
flutter run -d chrome
```

3. Database setup:
```bash
supabase db push
```

4. Deploy Edge Functions:
```bash
supabase functions deploy
```

## Data Pipeline

SEC data pipeline runs as scheduled GitHub Actions:

| Schedule | Job |
|---|---|
| Daily 2:15 AM | sync-sec-submissions |
| Daily 2:30 AM | sync-sec-companyfacts + parse + compute-metrics |
| Daily 2:45 AM | fetch-sec-filing-documents |
| Daily 3:00 AM | compute-data-quality |
| Weekdays 2:00 PM | sync-price-snapshots |
| Weekly Monday 6:00 AM | sync-fred-series + sync-bps-series |

## Testing

```bash
# Flutter tests
flutter test

# Python worker tests
cd workers && python -m pytest tests/
```

## Deployment

Push to `main` triggers GitHub Actions:
1. Analyze (`flutter analyze`)
2. Test (`flutter test`)
3. Build (`flutter build web --release`)
4. Deploy to Vercel

## License

MIT License — See [LICENSE](LICENSE)

## Links

- [Handoff Documentation](docs/HANDOFF/)
- [Governance Documents](docs/_temp/)
- [Architecture Docs](docs/)
