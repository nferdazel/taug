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
│   ├── config/              # AppEnv, envied config
│   ├── constants/           # Colors, sizes, strings
│   ├── errors/              # Failure/Result classes
│   ├── network/             # API client, WebSocket manager
│   ├── schema/              # Supabase schema name constants
│   ├── theme/               # Design tokens (colors, typography, spacing)
│   └── utils/               # Helpers, extensions
├── features/
│   ├── auth/
│   │   ├── data/            # Repositories, data sources, models
│   │   ├── domain/          # Entities, use cases
│   │   └── presentation/    # Pages, widgets, providers
│   ├── watchlist/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chart/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── news/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── calendar/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/             # Reusable components (buttons, cards, tables)
│   └── models/              # Shared data models
└── main.dart
```

Paths MUST strictly follow: `lib/features/[feature_name]/[data|domain|presentation]`.

---

## 4. CONCURRENCY & COMPUTATION (ISOLATES / WEB WORKERS)

- **Asynchronous Offloading:** Every JSON decoding/parsing operation from WebSockets or HTTP responses that exceeds 50 items MUST be offloaded using `compute()` (compiles to Web Workers on Flutter Web).
- **State Mapping Isolation:** Heavy data filtering, technical indicator calculations, and sorting must run entirely off the main thread.
- **Stream Throttling:** Throttle incoming raw stream data at the background compute layer before piping parsed objects into presentation signals. Max UI updates every 100ms.

---

## 5. RENDERING & MEMORY GUARDRAILS

- **Granular Re-renders:** Use the `signals` package for fine-grained reactivity. NO `setState` in multi-nested or high-frequency widgets.
- **Repaint Boundaries:** Every widget displaying flashing numbers, changing charts, or real-time tickers MUST be isolated with a `RepaintBoundary`.
- **Viewport Bound Collections:** Always use `ListView.builder` or `SliverList` with explicit `itemExtent` or `prototypeItem`. Never render unbounded tables.
- **Canvas Direct Drawing:** For complex charts (Candlesticks, Order Book Depth), use `CustomPainter` over heavy widget nesting.

---

## 6. UI/UX DESIGN SYSTEM (ANTI-AI-ISH, DATA-HEAVY)

### A. Design Principles
- NO oversized cards, excessive whitespace, giant padding, or soft pastel gradients.
- Financial terminals require precision, high data density, and professional utility.
- Base designs on: Shadcn UI (Zinc/Slate), Bloomberg Terminal aesthetics.

### B. Color Palette (Dark Mode Only)
| Token | Hex | Usage |
|---|---|---|
| Background | `#09090b` | Main background |
| Surface | `#18181b` | Cards, panels |
| Border | `#27272a` | Separators, 1px borders |
| Text Primary | `#fafafa` | Main text |
| Text Secondary | `#71717a` | Labels, captions |
| Bullish | `#10b981` | Positive change, green |
| Bearish | `#f43f5e` | Negative change, red |
| Accent | `#3b82f6` | Links, interactive elements |
| Warning | `#f59e0b` | Alerts, importance high |

### C. Typography
- **Mono (numbers, tickers, code):** IBM Plex Mono
- **Sans (UI text, labels, buttons):** IBM Plex Sans
- Monospace for ALL financial figures to ensure column alignment.

### D. Compact Mode (Default — Bloomberg-tier)
| Component | Default | Compact |
|---|---|---|
| Title | 16sp | 13sp |
| Body | 14sp | 11sp |
| Caption | 12sp | 9sp |
| Button Height | 40dp | 24-28dp |
| Table Cell Padding | 8v 12h | 2v 6h |
| Grid Spacing | 16dp | 4-6dp |

### E. Component Guardrails
- No hidden overflow on financial numbers. Use dynamic font scaling or strict column constraints.
- Borders over shadows. Use 1px borders (`#27272a`) instead of `BoxShadow`.
- Every button/row must have sharp feedback states (hover, focus) for mouse/keyboard.

---

## 7. SECURITY & PUBLIC REPO

- **Zero-Hardcoding Policy:** Never output hardcoded API Keys, Supabase URLs, Service Roles, or Anon Keys in code.
- **Envied Integration:** All environment variables use `@Envied` / `@EnviedField` with `obfuscate: true`.
- **Git Safeguard:** `env.g.dart` must never be committed (add to `.gitignore`). `.env.example` is committed with placeholder values.

---

## 8. CODE STYLE & BEST PRACTICES

- **Strong Typing:** Explicit types for all variables, method returns, and stream data. Minimize `dynamic`.
- **Immutability:** Use `const` constructors. All Domain Entities and Data Models must be immutable.
- **Error Handling:** Every network/WebSocket interaction wrapped in functional error wrapper (Either/Result pattern) or structured try-catch piping to dedicated presentation error signal.
- **No `dynamic`:** Avoid `dynamic` type. Use explicit types or `Object?` when truly needed.

---

## 9. GIT & COMMIT COMPLIANCE

- **Format:** `<type>(<scope>): <short description in lowercase>`
- **Allowed types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`
- **Author Identity:** `Fredianto <private@example.com>`
- **Micro-scopes:** Use specific scopes: `auth`, `watchlist`, `chart`, `news`, `calendar`, `settings`, `theme`, `ci`, `deps`, `core`, `shared`, `schema`

---

## 10. PRE-FLIGHT VERIFICATION CHECKLIST

Every code snippet MUST pass:
1. Is it encrypted via Envied?
2. Is heavy data processing safely in a `compute()` isolate/worker?
3. Does it protect the main thread from FPS drops on mobile browsers?
4. Are UI components wrapped in `RepaintBoundary` where applicable?
5. Does it adapt to Compact Mode tokens?
6. Is it fully typed with no `dynamic`?
7. Are all financial numbers displayed in monospace font?

If any answer is NO, rewrite before responding.

---

## 11. DEPENDENCIES (ALLOWED ONLY)

### Direct Dependencies
- `flutter` (SDK)
- `cupertino_icons`
- `supabase_flutter` (pinned version)
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

### Dev Dependencies
- `flutter_test` (SDK)
- `flutter_lints`
- `envied_generator`
- `build_runner`
- `flutter_lints`

### NEVER Add
- Provider, Bloc, Riverpod, GetX, MobX (use signals only)
- `setState` in high-frequency widgets
- Any deprecated packages

---

## 12. DEPLOYMENT

- **Platform:** Web only (WASM)
- **Hosting:** Vercel (taug.vercel.app)
- **CI/CD:** GitHub Actions (`deploy.yml`)
- **Flow:** Push to main → lint → test → build → deploy to Vercel
- **GitHub Secrets Required:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `TWELVE_DATA_API_KEY`, `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_ORG_ID`
