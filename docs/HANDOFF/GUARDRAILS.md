# TAUG — Guardrails

## Product Guardrails

### TAUG Is NOT:

| Non-Goal | Why | What Happens If Violated |
|---|---|---|
| Stock Screener | Screener is a tool, not the product | Product loses research focus |
| Finance Dashboard | Dashboards serve monitoring, not thinking | Users become passive consumers |
| Portfolio Tracker | Portfolio tracks decisions, not P&L | Users focus on returns, not research quality |
| Trading Platform | No broker integration | Users expect real-time features |
| AI Advisor | No recommendations | Users lose agency in decisions |
| News Platform | News is context, not core | Product becomes information consumption |
| Social Network | No sharing features | Users expect collaboration features |

### TAUG IS:

- Research Operating System
- Investment Decision Workspace
- Learning Platform
- Decision Support Tool

---

## Design Guardrails

### Do NOT:

- Add gradients, glassmorphism, neumorphism
- Create dashboard KPI cards
- Build floating hero sections
- Use Dribbble aesthetics
- Copy AI-generated SaaS patterns
- Add excessive shadows or borders
- Create admin-panel layouts

### DO:

- Use 1px borders
- Use monospace for financial data
- Use dark theme
- Maintain 4px grid
- Keep information dense
- Design from user intent

---

## Technical Guardrails

### Architecture:

- Flutter Web is non-negotiable
- Signals for state management
- Supabase for backend
- Python for data pipeline
- Desktop-first

### Code:

- Type safety (no `dynamic`)
- Repository pattern for data access
- Result<T> for error handling
- debugPrint for logging
- RepaintBoundary on high-frequency widgets

### Database:

- `taug` schema isolation
- RLS on user-owned tables
- Additive migrations only
- No destructive changes

---

## Workflow Guardrails

### Every Feature Must Serve:

1. Discover
2. Research
3. Thesis
4. Decision
5. Portfolio
6. Outcome
7. Learning

### Features That Do NOT Serve This Workflow:

- Real-time price monitoring
- Chart technical analysis
- News aggregation
- Social sharing
- AI recommendations
- Market sentiment

---

## Common Failure Modes

### 1. Dashboard Syndrome
**Symptom:** Adding KPI cards, charts, widgets to fill space
**Fix:** Every element must serve a user job

### 2. Data Viewer Thinking
**Symptom:** "Let me display this data" instead of "Let me support this decision"
**Fix:** Ask "What decision does this support?"

### 3. Feature Creep
**Symptom:** Adding features because they're easy, not because they serve the workflow
**Fix:** Every feature must pass the workflow test

### 4. Table-First Design
**Symptom:** Defaulting to DataTable for every data display
**Fix:** Ask "Is a table the best way to present this information?"

### 5. Metrics-First Design
**Symptom:** Leading with financial metrics instead of research context
**Fix:** Research state should be primary, metrics secondary

### 6. AI Feature Temptation
**Symptom:** "Let me add AI analysis"
**Fix:** TAUG presents data, not opinions. AI is explicitly excluded.

### 7. Real-Time Feature Temptation
**Symptom:** "Users need real-time prices"
**Fix:** TAUG is for research, not monitoring. Daily sync is sufficient.

### 8. Mobile-First Thinking
**Symptom:** Designing for mobile before desktop
**Fix:** Desktop-first. Research requires screen space.
