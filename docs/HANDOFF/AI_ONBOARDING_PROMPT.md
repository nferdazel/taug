# TAUG — AI Onboarding Prompt

Use this prompt as-is or with small adjustments.

```md
You are entering an existing Flutter Web project called TAUG.

TAUG is a Research Operating System for individual investors.
It is NOT a trading platform, dashboard, screener, or portfolio tracker.

Before making any judgment, read these files in order:

1. docs/HANDOFF/README.md
2. docs/HANDOFF/PROJECT_OVERVIEW.md
3. docs/HANDOFF/PRODUCT_PHILOSOPHY.md
4. docs/HANDOFF/WORKFLOW_ARCHITECTURE.md
5. docs/HANDOFF/DESIGN_PHILOSOPHY.md
6. docs/HANDOFF/ARCHITECTURE.md
7. docs/HANDOFF/GUARDRAILS.md
8. docs/HANDOFF/KNOWN_DEBTS.md
9. docs/HANDOFF/ROADMAP.md

After reading, you must adopt these assumptions:

1. Flutter Web is the non-negotiable platform.
2. Signals is the state management solution.
3. Supabase is the backend.
4. Python workers handle data pipeline.
5. Desktop-first is the correct approach.
6. Dark mode only is intentional.
7. AI features are intentionally excluded.
8. Real-time data is intentionally excluded.

Product philosophy:

- TAUG helps users THINK, not WATCH data.
- Every feature serves the research workflow.
- Portfolio tracks DECISIONS, not PRICES.
- Learning from outcomes is the long-term moat.
- Metrics are SECONDARY to research workflow.

Design philosophy:

- Information density over whitespace.
- Borders over shadows.
- Monospace for financial data.
- Research-first, not metrics-first.
- User intent drives layout, not widget availability.

When implementing features:

1. Ask: "What user job does this serve?"
2. Ask: "Does this support the research workflow?"
3. Ask: "Would a user call this a research product or a data viewer?"
4. If the answer is "data viewer", redesign.

When making architecture decisions:

1. Prefer simple solutions.
2. Prefer existing patterns.
3. Prefer additive changes.
4. Avoid premature optimization.
5. Avoid new dependencies unless necessary.

When reviewing code:

1. Run `flutter analyze` — target 0 errors, 0 warnings.
2. Run `pytest workers/tests/` — target all passing.
3. Verify navigation works.
4. Verify empty states work.
5. Verify error states work.

Common mistakes to avoid:

- Adding dashboard KPIs (TAUG is not a dashboard)
- Adding real-time features (TAUG is for research, not monitoring)
- Adding AI features (TAUG presents data, not opinions)
- Adding mobile-first design (desktop-first is correct)
- Using table-first layouts (workflow-first is correct)
- Leading with metrics (research-first is correct)
- Adding gradients/shadows (borders and flat design)

The project uses:

- Flutter 3.12+ with WASM compilation
- Dart SDK ^3.12.2
- signals for state management
- go_router for routing
- Supabase for backend (schema: taug)
- Python 3.12+ for data pipeline
- GitHub Actions for CI/CD
- Vercel for hosting

Key files to understand:

- lib/main.dart — App entry point
- lib/core/config/app_router.dart — Route definitions
- lib/core/theme/ — Design system
- lib/shared/widgets/ — Reusable components
- lib/features/ — Feature modules
- workers/taug_worker/ — Python data pipeline
- supabase/migrations/ — SQL migrations
- docs/ — Architecture and planning documents

Success means:

A user can discover companies, research them, form theses, track decisions, and learn from outcomes — without confusion, without dead ends, without obvious bugs.

Failure means:

The product feels like a data viewer, not a research workspace. Users consume data instead of thinking about decisions.
```
