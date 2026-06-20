# TAUG Handoff Package

**Date:** 2026-06-20
**Purpose:** Durable project memory for future developers, AI models, and sessions.

---

## What This Contains

This package contains everything needed to understand TAUG without prior conversation history.

| Document | Purpose |
|---|---|
| `PROJECT_OVERVIEW.md` | What TAUG is, what problem it solves, current state |
| `PRODUCT_PHILOSOPHY.md` | Why TAUG exists, design principles, historical pivots |
| `WORKFLOW_ARCHITECTURE.md` | User journey, research lifecycle, decision flow |
| `DESIGN_PHILOSOPHY.md` | Visual principles, workspace thinking, what to avoid |
| `ARCHITECTURE.md` | Tech stack, Flutter strategy, state management, data layer |
| `ROADMAP.md` | Current status, completed phases, remaining work |
| `GUARDRAILS.md` | Product, design, technical, workflow constraints |
| `KNOWN_DEBTS.md` | Intentional gaps, deferred decisions, documented issues |
| `AI_ONBOARDING_PROMPT.md` | Single prompt for onboarding new AI models |
| `README.md` | This file — reading guide |

---

## Recommended Reading Order

### For New Developers

1. `PROJECT_OVERVIEW.md` — understand what TAUG is
2. `PRODUCT_PHILOSOPHY.md` — understand why it exists
3. `ARCHITECTURE.md` — understand the tech stack
4. `DESIGN_PHILOSOPHY.md` — understand the design system
5. `GUARDRAILS.md` — understand constraints
6. `KNOWN_DEBTS.md` — understand what's intentionally incomplete

### For New AI Models

1. `AI_ONBOARDING_PROMPT.md` — read this first
2. `PROJECT_OVERVIEW.md`
3. `PRODUCT_PHILOSOPHY.md`
4. `WORKFLOW_ARCHITECTURE.md`
5. `DESIGN_PHILOSOPHY.md`
6. `ARCHITECTURE.md`
7. `GUARDRAILS.md`
8. `KNOWN_DEBTS.md`
9. `ROADMAP.md`

### For Quick Understanding

1. `PROJECT_OVERVIEW.md` — 5 minute read
2. `PRODUCT_PHILOSOPHY.md` — 5 minute read
3. `GUARDRAILS.md` — 3 minute read

---

## Quick Start

### What Is TAUG?

TAUG is a **Research Operating System** for individual investors. It helps users research companies, form investment theses, track decisions, and learn from outcomes.

### What Technology?

- **Frontend:** Flutter Web (WASM), Dart, Signals, go_router
- **Backend:** Supabase (PostgreSQL + Auth)
- **Data Pipeline:** Python workers (SEC EDGAR, FRED, BPS)
- **Hosting:** Vercel + GitHub Actions

### What's the Workflow?

```
Discover → Research → Thesis → Decision → Portfolio → Outcome → Learning
```

### What Should I NOT Do?

- ❌ Add AI features
- ❌ Add real-time data
- ❌ Add dashboard KPIs
- ❌ Add mobile-first design
- ❌ Turn it into a screener
- ❌ Turn it into a portfolio tracker

---

## New Developer Guide

1. Clone the repository
2. Read `PROJECT_OVERVIEW.md`
3. Read `ARCHITECTURE.md`
4. Run `flutter pub get`
5. Run `flutter analyze`
6. Run `flutter run -d chrome`
7. Read `GUARDRAILS.md` before making changes

---

## New AI Guide

1. Read `AI_ONBOARDING_PROMPT.md`
2. Follow the reading order
3. Understand the product philosophy
4. Understand the design philosophy
5. Understand the guardrails
6. Run `flutter analyze` before committing
7. Run `pytest workers/tests/` before committing
8. Create review documents in `docs/_temp/`

---

## Project Status

| Metric | Value |
|---|---|
| Companies | 18 with parsed statements |
| Metrics | 19 financial metrics |
| Workspaces | 6 (Companies, Company, Research, Portfolio, Data, Settings) |
| Workers | 9 Python jobs |
| Migrations | 46 SQL migrations |
| Tests | 74 pytest unit tests |
| Analyzer | 0 errors, 0 warnings |

---

## Key Constraints

1. **Flutter Web is non-negotiable.** No React, no Vue, no Svelte.
2. **Desktop-first.** Mobile is future.
3. **Dark mode only.** No light mode.
4. **No AI features.** TAUG presents data, not opinions.
5. **No real-time data.** Daily sync is sufficient.
6. **Research-first.** Every feature serves the research workflow.
