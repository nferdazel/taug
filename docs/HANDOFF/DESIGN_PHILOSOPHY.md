# TAUG — Design Philosophy

## Design Principles

### 1. Research Over Data

Every screen supports the research workflow. Data exists to support thinking, not to be consumed.

### 2. Density Over Whitespace

Research requires information density. Large empty spaces waste screen real estate. Compact, readable layouts serve users better than spacious dashboards.

### 3. Hierarchy Through Weight

Use font weight and color to create hierarchy. Not giant fonts. Not excessive spacing.

### 4. Borders Over Shadows

1px borders define space. Shadows are avoided. Clean, sharp edges communicate precision.

### 5. Monospace For Data

Financial numbers use monospace font. UI text uses sans-serif. This creates clear visual distinction between data and interface.

### 6. Consistent Rhythm

4px base unit. Everything aligns to grid. Consistent spacing creates professional feel.

---

## Workspace Thinking

Every page is a **workspace**, not a page.

A workspace supports a specific job:
- Companies Workspace: "Find companies to research"
- Company Workspace: "Research this company"
- Research Workspace: "Manage my research"
- Portfolio Workspace: "Track my decisions"

Each workspace has:
- Clear purpose
- Primary action
- Information hierarchy
- Empty state guidance

---

## Workflow Thinking

Design from user intent, not from available widgets.

Ask:
1. What is the user trying to accomplish?
2. What information do they need?
3. What action should they take?
4. What should be visible immediately?

Do NOT ask:
1. What widgets do I have?
2. What data can I display?
3. What tables can I show?

---

## Information Hierarchy

### Level 1: Identity (always first)
- Company name, ticker, sector

### Level 2: Decision Context (most important)
- Research status, thesis status, conviction

### Level 3: Key Metrics (supporting)
- PE, ROE, margins, D/E

### Level 4: Detailed Data (on demand)
- Financial statements, line items

### Level 5: Trust Layer (background)
- Quality badges, freshness indicators

---

## What To Avoid

### Visual Anti-Patterns
- ❌ Gradients
- ❌ Glassmorphism
- ❌ Neumorphism
- ❌ Floating KPI dashboards
- ❌ Giant cards
- ❌ Oversized empty states
- ❌ Excessive shadows
- ❌ Unnecessary borders
- ❌ Dashboard filler content

### Design Anti-Patterns
- ❌ Admin dashboard aesthetics
- ❌ AI-generated SaaS patterns
- ❌ Dribbble-style designs
- ❌ Marketing-style hero sections
- ❌ Table-first layouts
- ❌ Metric-first layouts

### Product Anti-Patterns
- ❌ Data viewers without workflow
- ❌ Dashboards without action
- ❌ Analytics without decisions
- ❌ Features without user jobs

---

## Preferred Design References

| Product | What to Learn |
|---|---|
| Linear | Information hierarchy, density, keyboard-first |
| Notion | Block-based content, flexible layouts |
| Readwise Reader | Reading workflow, annotation |
| Arc Browser | Tab management, workspace organization |
| Raycast | Command palette, keyboard navigation |
| Stripe Dashboard | Data presentation, professional feel |

**Do NOT copy visuals. Extract principles only.**

---

## Component Language

| Element | Style |
|---|---|
| Headers | 16px, w600, sans-serif |
| Body | 12px, w400, sans-serif |
| Data values | 14px, w600, monospace |
| Badges | 10px, w500, colored background |
| Tables | 32px header, 40px rows, 1px borders |
| Cards | 1px border, no shadow, 6px radius |
| Dialogs | 480px width, 36px fields |
| Empty states | 32px icon, 13px title, centered |
