# TAUG — Known Debts

## Product Debt

| Debt | Impact | Status |
|---|---|---|
| JPMorgan has no 10-K/10-Q data | Financials sector incomplete | Deferred — needs form-type filter |
| Oracle missing EV metrics | Balance sheet data incomplete | Deferred — XBRL catalog expansion |
| No Indonesia companies | Indonesia market not covered | Deferred — IDX integration needed |
| No quarterly toggle in financials | Limited analysis depth | Deferred |
| No historical metric trends | Can't see direction | Deferred |

## Design Debt

| Debt | Impact | Status |
|---|---|---|
| Dialog TextEditingControllers leak | Memory over time | Documented |
| Silent mutation errors | User sees no feedback on error | Documented |
| Text overflow in dense views | Visual bugs | Some fixed, some remaining |
| Duplicated date formatting | Maintenance burden | Documented |
| Duplicated stance/conviction chips | Maintenance burden | Documented |
| Settings page missing loading state | UX issue | Documented |
| DataWorkspacePage is a stub | Wasted tab slot | Documented |

## Technical Debt

| Debt | Impact | Status |
|---|---|---|
| Old terminal-era company page coexists | Confusion | Route redirects to new workspace |
| Old portfolio page coexists | Confusion | Route redirects to new workspace |
| Edge Functions still do ETL | Architecture inconsistency | Works, not urgent |
| No RepaintBoundary on cards | Performance | Documented |
| No keyboard shortcuts | Desktop UX | Documented |
| No automated tests in CI | Quality assurance | Documented |

## Workflow Debt

| Debt | Impact | Status |
|---|---|---|
| No automated stale thesis detection | Manual review needed | Deferred |
| No automated "needs review" detection | Manual review needed | Deferred |
| Lessons learned buried in position detail | Learning not visible | Deferred |
| No cross-company comparison | Limited analysis | Deferred |
| No research search across all notes/theses | Findability | Deferred |

## Deferred Decisions

| Decision | Status | When To Decide |
|---|---|---|
| Flutter vs React for new features | Flutter chosen | Non-negotiable |
| Supabase vs custom backend | Supabase chosen | Non-negotiable |
| Mobile-first vs desktop-first | Desktop chosen | Non-negotiable |
| AI features | Excluded | When product is mature |
| Indonesia expansion | Deferred | After US coverage is solid |
| Collaboration features | Deferred | After single-user workflow is proven |

## Intentionally Unfinished

| Item | Reason |
|---|---|
| Quarterly financial toggle | Not critical for MVP |
| Historical metric charts | Post-MVP |
| Screener expansion | Post-MVP |
| Advanced search | Post-MVP |
| Export functionality | Post-MVP |
| Multiple portfolios | Future |
| Benchmark comparison | Future |
