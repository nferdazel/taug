# TAUG Beta Test Plan

**Date:** 2026-06-22
**Phase:** Beta (RC4 Approved)
**Version:** 1.0.0 (Build 1)
**Platform:** Flutter Web (WASM) — Desktop only
**Duration:** 2 weeks per user
**Users:** 2–5

---

## 1. Objectives

| # | Objective | Success Criteria |
|---|---|---|
| 1 | Validate core research workflow end-to-end | User completes Discover → Research → Thesis → Position → Close → Lesson without external help |
| 2 | Identify friction points in real usage | 0 unresolved "I got stuck" moments per scenario |
| 3 | Verify data trust and quality perception | User trusts displayed data (≥3/4 on trust scale) |
| 4 | Confirm product value proposition | User would use TAUG again (≥3/4 on reuse scale) |
| 5 | Surface bugs not caught by automated tests | All P0 bugs logged within 48 hours of discovery |

---

## 2. Beta User Profile

### Selection Criteria

| Criterion | Requirement | Rationale |
|---|---|---|
| Investment style | Long-term equity (hold >6 months) | TAUG serves researchers, not traders |
| Research habit | Currently uses spreadsheets, notes, or docs for research | Tests the "structured research" value prop |
| Tech comfort | Comfortable with web apps, no onboarding needed | Removes tech-literacy as a confounding variable |
| Desktop usage | Primary device is laptop/desktop | App is desktop-first; mobile not supported |
| Experience mix | 2–3 experienced investors, 1–2 newer investors | Validates learnability vs power-user needs |

### Recommended Users

| # | Profile | Experience | Why |
|---|---|---|---|
| 1 | Portfolio manager / analyst | 5+ years | Tests power-user workflow, identifies missing fields |
| 2 | Active retail investor | 3–5 years | Tests "serious but non-pro" workflow |
| 3 | Research-oriented retail investor | 1–2 years | Tests learnability and guidance clarity |
| 4 | Value investor (Graham-style) | 5+ years | Tests thesis/conviction model fit |
| 5 | Growth investor | 2–4 years | Tests different research mental model |

### Excluded Profiles

- Day traders (TAUG is not a trading terminal)
- Mobile-only users (desktop-only product)
- Users with no investment experience (need baseline to evaluate)

---

## 3. Test Environment

| Item | Detail |
|---|---|
| URL | `taug.vercel.app` (or staging URL) |
| Auth | Username + password (auto-generated email: `username@taug.app`) |
| Browser | Chrome 120+ (primary), Firefox 120+ (secondary) |
| Screen | 1280px+ width recommended |
| Data | Pre-loaded companies with real financial data (Twelve Data, Yahoo Finance) |
| Duration | 2 weeks per user, structured scenarios in first 3 days, free-form after |

### Pre-Test Setup (Owner)

1. Create beta user accounts in Supabase Auth
2. Verify all API keys are active and rotated
3. Confirm at least 10 companies have complete data (overview + financials + metrics)
4. Verify thesis/notes/questions CRUD works end-to-end
5. Verify portfolio create/close/lesson flow works end-to-end
6. Run smoke test (Section 8 of VALIDATION_CHECKLIST.md)

---

## 4. Onboarding

### What Users Receive

1. **Welcome email** with:
   - URL to TAUG
   - Login credentials
   - 1-page quick start guide (see Appendix A)
   - Link to feedback form

2. **Quick start guide** (1 page):
   - "TAUG helps you research companies, track your investment theses, and learn from your decisions."
   - "Start by browsing companies → open one → read the overview → go to Research tab."
   - "Create a thesis when you have a view. Create a position when you're ready to invest."
   - "Close a position when you exit. Write what you learned."

3. **Feedback form** (see Appendix B) — submitted after each scenario

### What Users Do NOT Receive

- Video walkthroughs (tests raw discoverability)
- Feature documentation (tests intuitiveness)
- Live support during scenarios (tests self-sufficiency)

---

## 5. Test Scenarios

### Scenario 1: Research a Company from Scratch

**Goal:** Validate that a user can discover a company, understand its business, and assess data quality without guidance.

**Precondition:** User is logged in, has no prior research.

**Steps:**

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open TAUG | Main layout loads. Navigation visible. |
| 2 | Navigate to Companies workspace | List of companies displays with names, tickers, exchanges. |
| 3 | Search for "NVIDIA" (or any known company) | Company appears in search results. |
| 4 | Open NVIDIA company page | Company Overview tab loads. |
| 5 | Read the Overview tab | Key metrics (Market Cap, PE, ROE, margins, D/E) display. Data Trust section shows quality badge and freshness. |
| 6 | Hover over a metric (e.g., PE ratio) | Tooltip explains what the metric means. |
| 7 | Check Data Trust section | Quality percentage badge (green/amber/red) and freshness badge (Fresh/Recent/Aging/Stale) visible. |
| 8 | Switch to Financials tab | Financial statements load with period columns. Research Context sidebar shows data freshness. |
| 9 | Create a research note | Note dialog opens. User enters title and body. Note saves and appears in list. |
| 10 | Return to Overview tab | Research Snapshot now shows "1 Notes" count. |

**Capture (user reports):**

| Question | Scale |
|---|---|
| Was the purpose of TAUG clear within 30 seconds? | Yes / No / Partially |
| Could you find a company without help? | Yes / No |
| Did you understand what the metrics mean? | Yes / No / Some were unclear |
| Did the Data Trust section help you assess data quality? | Yes / No / Didn't notice it |
| Was creating a note intuitive? | Yes / No / Needed help |
| Any confusion or frustration? | Free text |

**Bugs to watch for:**
- Company search returns no results for valid tickers
- Metrics show "—" for companies that should have data
- Data Trust badge shows incorrect color for actual quality
- Note creation silently fails (no error feedback)
- Page takes >3 seconds to load

---

### Scenario 2: Create a Thesis

**Goal:** Validate that a user can form and record an investment thesis with all required structure.

**Precondition:** User has completed Scenario 1 (has at least one company with a note).

**Steps:**

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Company Workspace → Research tab | Research tab loads. Progress checklist shows steps (Notes ✓, Thesis, Questions, Position). |
| 2 | Click "Create Thesis" | Thesis dialog opens with all fields visible. |
| 3 | Enter thesis title | Title field accepts input. Character limit (if any) is clear. |
| 4 | Select stance: Bullish | Stance chip highlights. Options: Bullish / Bearish / Neutral. |
| 5 | Select conviction: High | Conviction chip highlights. Options: Low / Medium / High. |
| 6 | Write thesis summary | Summary text field accepts multi-line input. |
| 7 | Write bull case | Bull case field accepts multi-line input. |
| 8 | Write bear case | Bear case field accepts multi-line input. |
| 9 | Save thesis | Dialog closes. Thesis card appears in Research tab with title, stance badge, conviction badge. |
| 10 | Verify Research Progress | Checklist now shows Notes ✓, Thesis ✓. Counter shows "2/4". |

**Capture (user reports):**

| Question | Scale |
|---|---|
| Were all form fields clear and understandable? | Yes / No / Some were confusing |
| Did "Stance" and "Conviction" mean what you expected? | Yes / No |
| Were Bull Case and Bear Case fields sufficient? | Yes / No / Needed more structure |
| Did you miss any fields that should exist? | Free text |
| Was the workflow smooth (no dead ends)? | Yes / No |
| Does the thesis card show what you expected? | Yes / No |

**Bugs to watch for:**
- Thesis dialog doesn't close after save
- Thesis card doesn't render stance/conviction badges
- Research Progress counter doesn't update
- Stance or conviction selection doesn't persist
- Long text overflows in thesis card

---

### Scenario 3: Record Questions and Notes

**Goal:** Validate that a user can create research questions, answer them, and connect findings to their thesis.

**Precondition:** User has completed Scenario 2 (has a company with a thesis).

**Steps:**

| Step | Action | Expected Result |
|---|---|---|
| 1 | In Company Research tab, click "+" to add a question | Question dialog opens with text field and priority selector. |
| 2 | Enter question: "What is NVIDIA's AI revenue mix?" | Text field accepts input. |
| 3 | Select priority: High | Priority chip highlights (Low / Medium / High / Critical). |
| 4 | Save question | Question appears in Questions list with priority badge. |
| 5 | Create a second question with Critical priority | Question appears above the first (sorted by priority). |
| 6 | Click "Answer" on the first question | Answer dialog opens showing original question + answer text field. |
| 7 | Enter answer text | Text field accepts input. |
| 8 | Click "Mark Answered" | Question moves to "Answered" section. Answer text visible. |
| 9 | Create a research note with findings | Note dialog opens. Enter title and body with research findings. |
| 10 | Verify Research Progress | Checklist shows Notes ✓, Thesis ✓, Questions ✓. Counter shows "3/4". |
| 11 | Navigate to Research Workspace | Open Questions section shows unanswered critical/high questions. |

**Capture (user reports):**

| Question | Scale |
|---|---|
| Was creating a question clear? | Yes / No |
| Were priority levels meaningful? | Yes / No / Too many options |
| Was answering a question intuitive? | Yes / No / Needed help |
| Is the connection between questions, notes, and thesis clear? | Yes / No / Unclear |
| Did you find the Research Workspace useful? | Yes / No / Didn't check it |

**Bugs to watch for:**
- Question priority doesn't sort correctly
- Answer dialog doesn't show original question text
- Answered questions don't move to answered section
- Research Workspace doesn't show open questions
- Critical questions don't appear in "Needs Attention" hero

---

### Scenario 4: Create a Position

**Goal:** Validate that a user can convert research conviction into a portfolio position with proper context.

**Precondition:** User has completed Scenario 3 (company with thesis, notes, questions).

**Steps:**

| Step | Action | Expected Result |
|---|---|---|
| 1 | From Company Research tab, click "Create Position" on thesis card | Navigates to Portfolio Workspace with pre-populated context. |
| 2 | Verify company is pre-selected | Company name displays in Add Position dialog. |
| 3 | Verify thesis is pre-linked | Thesis title shows in dialog with lightbulb icon. |
| 4 | Verify conviction is auto-populated | Conviction matches thesis conviction (e.g., "High"). |
| 5 | Set entry date | Date picker opens. Select a date. |
| 6 | Set entry price (optional) | Enter a price value. Field accepts decimal input. |
| 7 | Add position notes (optional) | Enter notes about the position. |
| 8 | Save position | Dialog closes. Position appears in Active tab. |
| 9 | Verify position displays correctly | Company name, thesis title, conviction badge, days held, entry price visible. |
| 10 | Verify Research Progress | Company Research now shows "4/4" (Notes ✓, Thesis ✓, Questions ✓, Position ✓). |

**Capture (user reports):**

| Question | Scale |
|---|---|
| Was the "Create Position" button easy to find? | Yes / No / Needed help |
| Was pre-population of company/thesis/conviction helpful? | Yes / No / Didn't notice |
| Was entry date clear? | Yes / No |
| Was entry price optional field clear? | Yes / No / Confused by optional |
| Does the position in Portfolio show what you expected? | Yes / No |
| Any missing fields? | Free text |

**Bugs to watch for:**
- Pre-population doesn't carry company/thesis from Research tab
- Conviction doesn't auto-populate from thesis
- Entry date picker doesn't work on desktop
- Position doesn't appear in Active tab after save
- Days held shows incorrect count

---

### Scenario 5: Close Position and Create Lesson

**Goal:** Validate that a user can close a position, record the outcome, and capture lessons that feed back into future research.

**Precondition:** User has completed Scenario 4 (has an active position).

**Steps:**

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Portfolio Workspace → Active tab | Active positions display. |
| 2 | Click three-dot menu on the position | Menu shows: View Company, Mark for Review, Close Position. |
| 3 | Click "Close Position" | Close Position dialog opens. |
| 4 | Select outcome: Correct | Outcome selector shows Correct / Incorrect / Partial. Selected chip highlights. |
| 5 | Enter exit price | Price field accepts decimal input. |
| 6 | Write lessons learned | Multi-line text field for lessons. Guidance text visible (e.g., "What did you learn from this decision?"). |
| 7 | Save | Dialog closes. Position moves from Active to Closed tab. |
| 8 | Switch to Closed tab | Closed position shows: company, entry/exit dates, return %, outcome badge (green "Correct"). |
| 9 | Switch to Lessons tab | Lesson appears grouped under "From Correct Decisions". Shows stance, conviction, lesson text. |
| 10 | Switch to Patterns tab | Stance accuracy and conviction accuracy update. Overall win rate reflects new data. |
| 11 | Navigate back to Company Research | Research tab shows thesis with "PRIOR LESSONS" section if thesis dialog is opened. |
| 12 | Click "Apply to New Research" on lesson | Navigates to company's research workspace for follow-up research. |

**Capture (user reports):**

| Question | Scale |
|---|---|
| Was the close workflow easy to find? | Yes / No / Needed help |
| Was outcome selection (Correct/Incorrect/Partial) clear? | Yes / No |
| Was the lessons field guided enough? | Yes / No / Needed more prompts |
| Does the lesson appear where you expected? | Yes / No / Didn't find it |
| Is the Patterns tab useful? | Yes / No / Didn't check it |
| Would "Apply to New Research" be useful in practice? | Yes / No |

**Bugs to watch for:**
- Close Position menu item doesn't appear
- Outcome selection doesn't persist
- Return % calculation is incorrect
- Position doesn't move from Active to Closed
- Lesson doesn't appear in Lessons tab
- Lesson doesn't appear in thesis "PRIOR LESSONS" section
- Patterns tab doesn't update with new data

---

## 6. Free-Form Testing (Days 4–14)

After completing structured scenarios, users explore freely. Goal: surface edge cases, unexpected workflows, and feature requests.

### Prompts for Free-Form Use

1. "Use TAUG for your actual investment research this week. Add companies you're watching."
2. "Try creating multiple theses for the same company. Does the system handle it?"
3. "Try closing a position as 'Incorrect'. Does the lesson flow feel different?"
4. "Check the Research Workspace after a few days. Does the 'Needs Attention' section help?"
5. "Try the Settings page. Change timezone and density. Do changes persist?"

### Daily Log (User fills daily)

| Day | What I did | What worked | What didn't | Bugs found |
|---|---|---|---|---|
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |
| 9 | | | | |
| 10 | | | | |
| 11 | | | | |
| 12 | | | | |
| 13 | | | | |
| 14 | | | | |

---

## 7. Feedback Collection

### Per-Scenario Feedback (after each scenario)

Submitted via form (see Appendix B). Captures:
- Completion status (completed / got stuck / abandoned)
- Time to complete
- Confusion points (free text)
- Bugs observed (free text)
- Satisfaction (1–5 scale)

### End-of-Beta Feedback (after 2 weeks)

Submitted via BETA_FEEDBACK_TEMPLATE.md. Captures:
- First impression
- Confusing areas
- Most useful feature
- Least useful feature
- Missing features
- Workflow friction
- Trust level
- Would use again

### Bug Reports

Users report bugs via:
- Screenshot + description in feedback form
- Direct message to project owner
- Daily log entries

**Bug severity classification:**

| Severity | Definition | Response Time |
|---|---|---|
| P0 — Blocker | Cannot complete core workflow | < 24 hours |
| P1 — Critical | Feature broken but workaround exists | < 48 hours |
| P2 — Major | UX issue causing confusion | < 1 week |
| P3 — Minor | Cosmetic or low-impact issue | Backlog |

---

## 8. Success Metrics

| Metric | Target | Measurement |
|---|---|---|
| Scenario completion rate | ≥ 80% (4/5 scenarios completed without help) | Per-scenario feedback |
| Time to first value | < 5 minutes (user creates first note) | User-reported |
| Data trust score | ≥ 3/4 ("Mostly" or "Completely" trust data) | End-of-beta feedback |
| Reuse intent | ≥ 3/4 ("Yes, definitely" or "Yes, with improvements") | End-of-beta feedback |
| P0 bugs found | 0 (ideally) or fixed within 24 hours | Bug log |
| NPS (Net Promoter Score) | ≥ 30 (calculated from reuse intent) | End-of-beta feedback |

---

## 9. Known Limitations (Disclosed to Users)

These are known issues users may encounter. They are documented so users don't waste time reporting them.

| # | Limitation | Impact | Workaround |
|---|---|---|---|
| 1 | Single thesis per company | Can't track thesis evolution | Create new note documenting thesis change |
| 2 | No mobile support | Not usable on phone/tablet | Use desktop browser |
| 3 | No real-time price updates | Prices may be delayed | Check external source for current prices |
| 4 | No charts/visualizations | Data shown in tables only | Use external charting tools |
| 5 | No export/download | Can't export research | Copy-paste from UI |
| 6 | Limited company universe | Not all companies available | Focus on pre-loaded companies |
| 7 | No email notifications | No alerts for stale research | Check Research Workspace manually |

---

## 10. Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| User abandons after Day 1 | Medium | High | Send Day 2 check-in email with encouragement |
| User doesn't complete all scenarios | Medium | Medium | Prioritize Scenarios 1, 2, 5 (core loop) |
| User encounters P0 bug | Low | High | Owner on standby for first 72 hours |
| User provides vague feedback | Medium | Medium | Structured feedback forms with specific questions |
| User compares to Bloomberg/TradingView | High | Low | Onboarding sets expectations: "Research tool, not terminal" |

---

## 11. Timeline

| Day | Activity | Owner | User |
|---|---|---|---|
| -3 | Create accounts, verify environment | Owner | — |
| -1 | Send welcome email with credentials | Owner | — |
| 1 | User logs in, completes Scenario 1 | — | User |
| 2 | User completes Scenarios 2 + 3 | — | User |
| 3 | User completes Scenarios 4 + 5 | — | User |
| 4–14 | Free-form testing + daily logs | — | User |
| 14 | Submit end-of-beta feedback | — | User |
| 15 | Owner reviews all feedback | Owner | — |
| 16 | Owner triages bugs (P0/P1/P2/P3) | Owner | — |
| 17 | Owner publishes beta summary report | Owner | — |

---

## 12. Post-Beta Actions

| # | Action | Timeline |
|---|---|---|
| 1 | Fix all P0 bugs | Within 48 hours of report |
| 2 | Fix all P1 bugs | Within 1 week |
| 3 | Triage P2/P3 bugs into backlog | Within 1 week |
| 4 | Publish beta summary report | Day 17 |
| 5 | Decide: ship, iterate, or extend beta | Day 18 |
| 6 | Thank users + share what was learned | Day 18 |

---

## Appendix A: Quick Start Guide (1 Page)

### Welcome to TAUG

TAUG helps you research companies, track your investment theses, and learn from your decisions.

**Get started in 3 steps:**

1. **Browse companies** — Click "Companies" in the sidebar. Search for a company you're interested in.
2. **Research it** — Open the company page. Read the overview and financials. Go to the Research tab and create a note about what you find.
3. **Form a thesis** — In the Research tab, click "Create Thesis." Write your bull case, bear case, and set your conviction.

**When you're ready to invest:**
- Click "Create Position" on your thesis card. Set your entry date and price.

**When you exit:**
- Go to Portfolio → click the menu → "Close Position." Record the outcome and write what you learned.

**The goal:** Build a record of your thinking so you can learn from your decisions over time.

---

## Appendix B: Per-Scenario Feedback Form

### Scenario [N]: [Scenario Name]

**Did you complete the scenario?**
- [ ] Yes, without help
- [ ] Yes, with some difficulty
- [ ] Got stuck (describe below)
- [ ] Abandoned

**Time to complete:** ___ minutes

**What confused you?** (free text)

___________________________________________________________________________

___________________________________________________________________________

**What frustrated you?** (free text)

___________________________________________________________________________

___________________________________________________________________________

**Did you encounter any bugs?** (describe + screenshot if possible)

___________________________________________________________________________

___________________________________________________________________________

**Satisfaction (1–5):**

| 1 — Very dissatisfied | 2 — Dissatisfied | 3 — Neutral | 4 — Satisfied | 5 — Very satisfied |
|---|---|---|---|---|
| [ ] | [ ] | [ ] | [ ] | [ ] |

**Anything else?** (optional)

___________________________________________________________________________

___________________________________________________________________________

---

*This test plan is maintained by QA. Update after each beta cycle.*
