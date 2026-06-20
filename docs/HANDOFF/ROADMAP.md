# TAUG — Roadmap

## Current Status

**Phase:** Beta Hardening Complete
**Companies:** 18 with parsed financial statements
**Metrics:** 19 financial metrics
**Workspaces:** 6 (Companies, Company, Research, Portfolio, Data, Settings)
**Test Coverage:** 74 unit tests

---

## Completed Phases

| Phase | Status | Key Deliverable |
|---|---|---|
| Foundation Cleanup V2 | ✅ | Schema, migrations, source registry |
| Companies Workspace | ✅ | Company list, search, badges |
| Company Workspace | ✅ | Overview, Financials, Research tabs |
| Research Workspace | ✅ | Queue, theses, notes, search |
| Portfolio Workspace | ✅ | Decision journal, close workflow |
| UX / Polish Pass | ✅ | Metric tooltips, trust badges |
| Visual Maturity | ✅ | Constrained width, consistent headers |
| Workspace Architecture | ✅ | Research-first layout |
| Workflow Activation | ✅ | Decision prompts, state transitions |
| Beta Hardening | ✅ | Error handling, delete confirmation |

---

## D1 Lessons

### What Worked
- Research-first layout
- Decision prompt guidance
- Section-driven Research Workspace
- Company search in Portfolio

### What Didn't Work
- Tab-driven layouts (Research, Portfolio)
- Metrics-first thinking
- Decorative workflow actions
- UUID-based company selection

### Key Insight
**Design from user intent, not from widget availability.**

---

## Remaining Work

### Priority 1: Data Expansion
- Expand SEC universe to 50+ companies
- Fix JPMorgan 10-K/10-Q issue
- Address Twelve Data rate limits

### Priority 2: Indonesia Expansion
- IDX company data
- BI macro data
- OJK regulatory data

### Priority 3: Advanced Features
- Charts and visualization
- Comparison workspace
- Historical metric trends
- Export functionality

### Priority 4: Mobile
- Responsive layouts
- Touch-friendly interactions
- Mobile-specific workflows

---

## Beta Hardening

### Production Blockers: None

### Known Issues (Non-blocking)
- Silent mutation errors (user sees no feedback)
- Dialog controller leaks (memory over time)
- Text overflow in dense views
- No keyboard shortcuts

### Monitoring Required
- Silent error rates
- Memory usage patterns
- Performance with real users

---

## Future Possibilities

| Feature | Priority | Effort |
|---|---|---|
| Screener expansion | Medium | Low |
| Indonesia companies | Medium | High |
| Historical trends | Low | Medium |
| Collaboration | Low | High |
| AI features | Low | High |
| Mobile app | Low | High |

---

## What Should NOT Happen Next

- ❌ AI features (product not ready)
- ❌ Real-time data (not aligned with research workflow)
- ❌ Social features (not core value proposition)
- ❌ Mobile app (desktop-first is correct)
- ❌ Broker integration (decision journal, not trading platform)
