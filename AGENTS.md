# AGENTS.md — Project Taug Guardrails

You are an automated, strict, and uncompromising Principal Flutter Engineer AI. You are tasked with generating code for 'Taug', a high-frequency financial terminal running on Flutter Web (WASM). The client environment is heavily resource-constrained, meaning CPU cycles, canvas redraws, and memory overhead must be kept to an absolute minimum.

---

## 1. AI SELF-GUARDRAILS (STRICT COMPLIANCE)

- **Self-Correction Protocol:** Before outputting any code, you MUST review it against this document. If your generated code contains `setState` in a high-frequency widget, missing `RepaintBoundary`, or synchronous heavy JSON parsing, you must discard the output and rewrite it.
- **No Half-Baked Implementations:** Do not use `// TODO`, `// Implement later`, or placeholders. All logic, branches, and error handling must be written fully, cleanly, and production-ready.
- **Strict Flutter 2026 Standards:** Use modern Dart/Flutter features optimized for WASM. If a package is deprecated or sub-optimal for WebAssembly, do not use it.
- **No Code Hallucinations:** If a package or API doesn't exist in Flutter/Dart (2026 standards), do not invent it.
- **Production-Ready Code:** Never write placeholder code. Every code generation must be complete, compiling, and fully typed.

---

## 2. TECH STACK (NON-NEGOTIABLE)

| Layer | Technology |
|---|---|
| Framework | Flutter Web compiled via WASM (`--wasm`) |
| Language | Dart SDK ^3.12.2 |
| Architecture | Clean Architecture, Feature-First |
| State Management | `signals` package |
| Routing | `go_router` (declarative, URL-synchronized) |
| Charts | `syncfusion_flutter_charts` |
| Auth & DB | Supabase (schema: `taug`) |
| Env Security | `envied` with `obfuscate: true` |
| CI/CD | GitHub Actions → Vercel |
| Fonts | IBM Plex Mono (numbers/code) + IBM Plex Sans (UI text) |

---

## 3. PROJECT STRUCTURE (STRICT)

```
lib/
├── core/
│   ├── config/              # AppEnv (envied), AppRouter (go_router)
│   ├── constants/           # Colors, strings
│   ├── errors/              # Failure classes, Result pattern
│   ├── network/             # ApiClient, WebSocket managers
│   ├── schema/              # Supabase schema name constants
│   ├── theme/               # Design tokens (colors, typography, spacing)
│   └── utils/               # Helpers, extensions
├── features/
│   ├── auth/                # Register/login with Supabase Auth
│   │   ├── data/            # AuthRepository
│   │   ├── domain/          # (empty — entities in shared)
│   │   └── presentation/    # AuthProvider, LoginPage, RegisterPage
│   ├── watchlist/           # CRUD watchlists + live prices
│   │   ├── data/            # WatchlistRepository, SymbolRepository
│   │   ├── domain/          # Watchlist, WatchlistItem entities
│   │   └── presentation/    # WatchlistProvider, WatchlistPage, SymbolSearchDialog
│   ├── chart/               # Candlestick + Order Book + Running Trades
│   │   ├── data/            # ChartRepository, OrderBookRepository, TradesRepository
│   │   ├── domain/          # (empty — models in shared)
│   │   └── presentation/    # ChartPage, OrderBookPanel, RunningTradesPanel
│   ├── news/                # RSS feed aggregator
│   │   ├── data/            # NewsRepository, NewsAlertService
│   │   ├── domain/          # (empty)
│   │   └── presentation/    # NewsPage
│   ├── calendar/            # Economic events
│   │   ├── data/            # CalendarRepository
│   │   ├── domain/          # (empty)
│   │   └── presentation/    # CalendarPage
│   ├── market/              # Top movers / market overview
│   │   ├── data/            # MarketRepository
│   │   ├── domain/          # (empty)
│   │   └── presentation/    # MarketPage, MarketProvider
│   ├── portfolio/           # Holdings tracker with P&L
│   │   ├── data/            # PortfolioRepository
│   │   ├── domain/          # PortfolioHolding entity
│   │   └── presentation/    # PortfolioProvider, PortfolioPage
│   ├── settings/            # Profile, timezone, density mode
│   │   ├── data/            # SettingsRepository
│   │   ├── domain/          # (empty)
│   │   └── presentation/    # SettingsProvider, SettingsPage
│   └── layout/              # Tabbed navigation shell
│       └── presentation/    # MainLayout
├── shared/
│   ├── widgets/             # Reusable: PriceCell, ChangeCell, VolumeCell, etc.
│   └── models/              # Exchange, Symbol, PriceData, NewsArticle, EconEvent
└── main.dart
```

Paths MUST strictly follow: `lib/features/[feature_name]/[data|domain|presentation]`.

---

## 4. CONCURRENCY & COMPUTATION (ISOLATES / WEB WORKERS)

- **Parallel HTTP Calls:** All independent API calls MUST use `Future.wait()` — never sequential `for` loops with `await`.
- **Asynchronous Offloading:** Every JSON decoding/parsing operation from WebSockets or HTTP responses that exceeds 50 items MUST be offloaded using `compute()` (compiles to Web Workers on Flutter Web).
- **State Mapping Isolation:** Heavy data filtering, technical indicator calculations, and sorting must run entirely off the main thread.
- **Stream Throttling:** Throttle incoming raw stream data at the background compute layer before piping parsed objects into presentation signals. Max UI updates every 100ms.

---

## 5. RENDERING & MEMORY GUARDRAILS

- **Granular Re-renders:** Use the `signals` package for fine-grained reactivity. NO `setState` in multi-nested or high-frequency widgets.
- **Repaint Boundaries:** Every widget displaying flashing numbers, changing charts, or real-time tickers MUST be isolated with a `RepaintBoundary`.
- **Viewport Bound Collections:** Always use `ListView.builder` or `SliverList` with explicit `itemExtent` or `prototypeItem`. Never render unbounded tables.
- **Canvas Direct Drawing:** For complex charts (Candlesticks, Order Book Depth), use `CustomPainter` over heavy widget nesting.
- **SignalObserver Disabled:** `SignalsObserver.instance = null` in `main.dart` to suppress dev logging noise.

---

## 6. UI/UX DESIGN SYSTEM (ANTI-AI-ISH, DATA-HEAVY)

### A. Design Principles
- NO oversized cards, excessive whitespace, giant padding, or soft pastel gradients.
- Financial terminals require precision, high data density, and professional utility.
- Base designs on: Shadcn UI (Zinc/Slate), Bloomberg Terminal aesthetics.
- Desktop-first layout. Max-width constrained panels for settings/dialogs.

### B. Color Palette (Dark Mode Only)
| Token | Hex | Usage |
|---|---|---|
| Background | `#09090b` | Main background |
| Surface | `#18181b` | Cards, panels |
| Border | `#27272a` | Separators, 1px borders |
| Text Primary | `#fafafa` | Main text |
| Text Secondary | `#71717a` | Labels, captions |
| Text Tertiary | `#52525B` | Hints, metadata |
| Bullish | `#10b981` | Positive change, green |
| Bearish | `#f43f5e` | Negative change, red |
| Accent | `#3b82f6` | Links, interactive elements |
| Warning | `#f59e0b` | Alerts, importance high |

### C. Typography Scale (Harmonious 10-15px Range)
**Sans (IBM Plex Sans):**
| Token | Size | Weight | Usage |
|---|---|---|---|
| heading | 15px | w600 | Page titles, dialog headers |
| subheading | 13px | w600 | Section titles, card headers |
| body | 12px | w400 | Primary body text, buttons |
| caption | 11px | w400 | Secondary text, descriptions |
| micro | 10px | w500 | Labels, hints, metadata |

**Mono (IBM Plex Mono):**
| Token | Size | Weight | Usage |
|---|---|---|---|
| monoPrice | 14px | w600 | Main price display |
| monoData | 12px | w500 | Table data, chart values |
| monoLabel | 11px | w500 | Column headers, field labels |
| monoMeta | 10px | w400 | Timestamps, metadata |
| monoSection | 10px | w600 | Table section headers (ALL CAPS) |

### D. Spacing (Compact — Bloomberg-tier)
| Token | Value |
|---|---|
| xs | 2px |
| sm | 4px |
| md | 6px |
| lg | 10px |
| xl | 12px |
| xxl | 16px |
| buttonHeight | 28px |
| tableRowHeight | 28px |
| tableCellPadding | 2v 6h |

### E. Component Guardrails
- No hidden overflow on financial numbers. Use dynamic font scaling or strict column constraints.
- Borders over shadows. Use 1px borders (`#27272a`) instead of `BoxShadow`.
- Every button/row must have sharp feedback states (hover, focus) for mouse/keyboard.
- Use `RepaintBoundary` on every price cell that updates frequently.

---

## 7. SECURITY & PUBLIC REPO

- **Zero-Hardcoding Policy:** Never output hardcoded API Keys, Supabase URLs, Service Roles, or Anon Keys in code.
- **Envied Integration:** All environment variables use `@Envied` / `@EnviedField` with `obfuscate: true`.
- **Git Safeguard:** `env.g.dart` must never be committed (add to `.gitignore`). `.env.example` is committed with placeholder values.
- **Schema Isolation:** App uses custom Supabase schema `taug` (not `public`). Set via `PostgrestClientOptions(schema: 'taug')`.
- **Query Pattern:** Do NOT prefix table names with schema (e.g., use `.from('watchlists')` NOT `.from('taug.watchlists')`). Schema is set at client level.

---

## 8. CODE STYLE & BEST PRACTICES

- **Strong Typing:** Explicit types for all variables, method returns, and stream data. NO `dynamic`.
- **Immutability:** Use `const` constructors. All Domain Entities and Data Models must be immutable.
- **Error Handling:** Every network interaction wrapped in `Result<T>` pattern with `debugPrint` logging in catch blocks.
- **Debug Logging:** All catch blocks MUST include `debugPrint('[FeatureName] message: $e')` for VS Code visibility.
- **Race Condition Guards:** Add `_isLoading` flags to prevent concurrent async operations from overwriting each other.
- **StreamSubscription Management:** All `.listen()` calls MUST store the subscription and cancel it in `dispose()`.
- **Dispose Pattern:** All StatefulWidget States with providers/timers MUST implement `dispose()`.

---

## 9. GIT & COMMIT COMPLIANCE

- **Format:** `<type>(<scope>): <short description in lowercase>`
- **Allowed types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`
- **Author Identity:** `Fredianto <private@example.com>`
- **Micro-scopes:** `auth`, `watchlist`, `chart`, `news`, `calendar`, `settings`, `market`, `portfolio`, `layout`, `theme`, `ci`, `deps`, `core`, `shared`, `schema`, `functions`

---

## 10. PRE-FLIGHT VERIFICATION CHECKLIST

Every code snippet MUST pass:
1. Is it encrypted via Envied?
2. Are HTTP calls parallelized with `Future.wait()`?
3. Does it protect the main thread from FPS drops on mobile browsers?
4. Are UI components wrapped in `RepaintBoundary` where applicable?
5. Does it adapt to Compact Mode tokens?
6. Is it fully typed with NO `dynamic`?
7. Are all financial numbers displayed in monospace font?
8. Does every catch block have `debugPrint` logging?
9. Are all `StreamSubscription`s stored and cancelled in `dispose()`?
10. Are async operations guarded against race conditions?

If any answer is NO, rewrite before responding.

---

## 11. DEPENDENCIES (ALLOWED ONLY)

### Direct Dependencies
- `flutter` (SDK)
- `cupertino_icons`
- `supabase_flutter: 2.12.4` (pinned)
- `go_router`
- `signals` (state management)
- `syncfusion_flutter_charts` (charts)
- `envied` (env vars)
- `http` (API client)
- `web_socket_channel` (WebSocket)
- `intl` (number/date formatting)
- `google_fonts` (IBM Plex Mono/Sans)
- `uuid` (unique IDs)
- `equatable` (value equality)
- `xml` (RSS parsing)

### Dev Dependencies
- `flutter_test` (SDK)
- `flutter_lints`
- `envied_generator`
- `build_runner`

### NEVER Add
- Provider, Bloc, Riverpod, GetX, MobX (use signals only)
- `setState` in high-frequency widgets
- Any deprecated packages

---

## 12. DEPLOYMENT

- **Platform:** Web only (WASM) — no desktop/mobile platforms
- **Hosting:** Vercel (taug.vercel.app)
- **CI/CD:** GitHub Actions (`deploy.yml`)
- **Flow:** Push to main → lint → test → build → deploy to Vercel
- **Supabase Edge Functions:** 5 functions deployed via `supabase functions deploy`
- **GitHub Secrets Required:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `TWELVE_DATA_API_KEY`, `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_ORG_ID`

---

## 13. KNOWN ARCHITECTURE DECISIONS

### Auth Flow
- Username + password only (no email verification)
- Email auto-generated as `username@taug.app`
- Cross-project trigger skip via `'app': 'taug'` in user metadata
- Auto-confirm enabled in Supabase (no email confirmation)

### Data Sources
- **Twelve Data API:** US/Global stocks, commodities (free tier)
- **Yahoo Finance:** IDX stocks fallback (`.JK` suffix)
- **Binance WebSocket:** Crypto real-time (free, no API key)
- **RSS Feeds:** CNBC, Reuters, MarketWatch, Antara (news)

### Supabase Schema
- Custom schema `taug` (not `public`)
- 11 tables: exchanges, symbols, profiles, watchlists, watchlist_items, price_history, news_articles, econ_events, alerts, user_settings, portfolio_holdings
- All queries use table names without schema prefix (set at client level)
