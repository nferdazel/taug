# TAUG — Project Overview

## What Is TAUG

TAUG is a **Research Operating System** for individual investors.

It is a desktop-first Flutter Web application that helps long-term equity investors research companies, form investment theses, track decisions, and learn from outcomes.

TAUG is built on Supabase (PostgreSQL + Auth + Storage) with a Python data pipeline for SEC EDGAR financial data ingestion.

---

## What Problem TAUG Solves

Individual investors research companies across multiple disconnected tools — spreadsheets, note apps, financial websites, broker platforms. Research context is scattered. Decisions lack documentation. Learning from past decisions is nearly impossible.

TAUG consolidates the research workflow into one workspace:

**Discover → Research → Thesis → Decision → Portfolio → Outcome → Learning**

---

## Product Vision

TAUG is an **investment decision workspace**, not a financial data terminal.

Users should think:
- "What do I think about this company?"
- "Is my thesis still valid?"
- "What did I learn from my last decision?"

Users should NOT think:
- "What's the stock price right now?"
- "What does the chart look like?"
- "What's trending in the market?"

---

## Product Philosophy

### Research First
Every feature serves the research workflow. Data exists to support thinking, not to be consumed passively.

### Decision Support
TAUG helps users make and track investment decisions. It is not a data viewer.

### Portfolio As Decision Tracking
Portfolio Workspace tracks investment decisions — not prices, not P&L, not broker activity.

### Learning System
Closed positions record outcomes and lessons. Users should learn from their own decisions over time.

### Metrics Are Secondary
Financial metrics support research decisions. They are not the product. A user with good notes and a clear thesis is more valuable than a user with perfect metrics.

---

## Core Concepts

| Concept | Purpose |
|---|---|
| Company Workspace | Deep research on a single company |
| Research Workspace | Cross-company research management |
| Portfolio Workspace | Decision tracking and outcome recording |
| Thesis | Structured investment argument (bull/bear/neutral) |
| Conviction | Confidence level in a thesis (low/medium/high) |
| Quality Score | Data reliability indicator (0-100%) |
| Freshness Badge | Data age indicator (fresh/aging/stale/expired) |

---

## Why TAUG Exists

The creator (Fredianto) is a long-term equity investor based in Indonesia who needed:
- A place to research US and Indonesian companies
- A way to track investment decisions and learn from outcomes
- A tool that supports thinking, not just data consumption
- An Indonesia-first platform that can expand globally

---

## Target Users

**Primary:** Long-term equity investors (individual, not institutional)

**Characteristics:**
- Research companies before investing
- Form investment theses
- Track decisions over time
- Learn from outcomes
- Desktop-first workflow

**NOT target:** Traders, day traders, quant analysts, portfolio managers

---

## Current Product State

### What Works

| Feature | Status |
|---|---|
| Companies Workspace | ✅ Company list, search, quality badges, freshness badges |
| Company Workspace | ✅ Overview, Financials, Research tabs |
| Research Workspace | ✅ Queue, theses index, notes index, search |
| Portfolio Workspace | ✅ Active/closed positions, add/close workflows |
| Data Pipeline | ✅ SEC EDGAR, FRED, BPS ingestion |
| Metric Engine | ✅ 19 financial metrics, reproducible |
| Screener | ✅ Filter, sort, save |
| Trust Layer | ✅ Quality, freshness, source attribution |

### What Does NOT Work Yet

| Feature | Status |
|---|---|
| Indonesia companies | ❌ Not implemented |
| Real-time prices | ❌ Daily sync only |
| Charts | ❌ Not implemented |
| Mobile adaptation | ❌ Desktop only |
| AI features | ❌ Intentionally excluded |

---

## Current Product Capabilities

### Data
- 18 SEC companies with parsed financial statements
- 5 FRED macro series (US)
- 4 BPS macro series (Indonesia)
- 124 XBRL concepts
- 19 financial metrics
- 8 serving views

### Workspaces
- Companies: browse, search, quality/freshness badges
- Company: overview, financials, research tabs
- Research: queue, theses, notes, search
- Portfolio: active/closed positions, decision tracking
- Data: quality, freshness, sources
- Settings: home market, currency, preferences

### Workflows
- Discover → Research → Thesis → Decision → Portfolio → Outcome → Learning

---

## Non Goals

TAUG is NOT:

| Non-Goal | Why |
|---|---|
| Bloomberg Terminal | TAUG is research-focused, not terminal-focused |
| Finance Dashboard | TAUG helps users think, not watch |
| Screener Product | Screener is a tool, not the product |
| Portfolio Tracker | Portfolio tracks decisions, not P&L |
| Trading Platform | No broker integration, no trading |
| AI Advisor | No AI features, no recommendations |
| Social Network | No sharing, no collaboration (yet) |
| News Platform | No news aggregation (yet) |
| Mobile App | Desktop-first, mobile is future |
