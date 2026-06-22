# TAUG Owner Validation Checklist

Manual verification checklist for all implemented features. Check each item after confirming expected behavior.

---

## 1. Company Overview

Navigate to any company page → Overview tab.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 1.1 | Next Action banner displays | Blue left-border banner shows contextual guidance (e.g., "Create Thesis", "Answer Questions"). Banner hides when research is complete. |
| 1.2 | Next Action button works | Clicking the action button switches to Research tab or navigates to Portfolio. |
| 1.3 | Research Snapshot cells show data | Four cells (Thesis, Notes, Questions, Position) display counts and status. Empty cells show "Create" links. |
| 1.4 | Data Trust section renders | Quality badge shows percentage (green ≥80%, amber ≥50%, red <50%). Freshness badge shows Fresh/Recent/Aging/Stale. |
| 1.5 | Key Metrics grid shows 6 metrics | Market Cap, PE, ROE, Gross Margin, Net Margin, D/E display in 3-column grid. Missing metrics show "—". |
| 1.6 | Metric tooltips work | Hovering any metric shows explanation (e.g., "Price-to-Earnings ratio"). |
| 1.7 | Freshness tint on metrics | Left border color matches freshness status (green/amber/red). |
| 1.8 | About section shows description | Company description appears below metrics if available. |

---

## 2. Company Research

Navigate to any company page → Research tab.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 2.1 | Research Progress checklist shows 4 steps | Steps: Notes, Thesis, Questions, Position. Counter shows "X/4". |
| 2.2 | Completed steps show green checkmark | Steps with data show checkmark icon and green summary text. |
| 2.3 | Suggested Next Step displays | Blue banner shows next recommended action based on research progression. |
| 2.4 | Thesis card renders with badges | Title, stance badge (Bullish/Neutral/Bearish), conviction badge (Low/Medium/High) visible. |
| 2.5 | Thesis sections are collapsible | Clicking Bull Case, Bear Case, Assumptions, Catalysts, Risks, Exit Conditions toggles content. |
| 2.6 | Thesis Create Position button works | Navigates to Portfolio Workspace with pre-populated company/thesis data. |
| 2.7 | Thesis Edit/Delete via popup menu | Three-dot menu offers Edit and Delete options. Edit opens pre-filled dialog. |
| 2.8 | Empty thesis state shows guidance | "No thesis yet" message with "Create Thesis" button when no thesis exists. |
| 2.9 | Question creation with priority | Dialog allows entering question text and selecting priority (Low/Medium/High/Critical). |
| 2.10 | Question answer dialog works | Clicking "Answer" opens dialog showing original question + answer text field. |
| 2.11 | Question deletion with confirmation | Delete shows confirmation dialog before removing. |
| 2.12 | Note CRUD works | Create, Edit, Delete notes via dialogs. Notes show title, body preview, and date. |
| 2.13 | Empty states show framework | Empty states display: State → Why → What → Action pattern. |
| 2.14 | Prior Lessons section in thesis dialog | If company has closed positions, lessons appear at top of thesis dialog. |

---

## 3. Research Workspace

Navigate to Research in main navigation.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 3.1 | Header shows counters | Companies count, theses count, notes count, questions count badges display. |
| 3.2 | Search filters results | Typing in search field filters companies, theses, notes, and questions in real-time. |
| 3.3 | Needs Attention hero shows critical items | Companies with notes but no thesis, stale theses (>90 days), critical/high questions appear. |
| 3.4 | "All research is up to date" shows when clear | Green success banner displays when no attention items exist. |
| 3.5 | Active Research section shows companies | Companies with theses display with note/thesis counts and research status badge. |
| 3.6 | Active Research cards navigate | Clicking a company card navigates to that company's workspace. |
| 3.7 | Open Questions section displays | Critical and high priority questions show with company name, days open, notes count. |
| 3.8 | Recent Activity merged timeline | Theses and notes sorted by update time. Each entry shows type badge, title, company, time ago. |
| 3.9 | Empty sections are hidden | Sections with no data (Active Research, Open Questions, Recent Activity) do not render. |
| 3.10 | Attention items are clickable | Clicking an attention item navigates to the relevant company. |

---

## 4. Financials

Navigate to any company page → Financials tab.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 4.1 | Two-pane layout renders | Left pane shows financial statements, right pane shows Research Context sidebar. |
| 4.2 | Statement tables display correctly | Income Statement, Balance Sheet, Cash Flow sections show period columns (up to 4 recent). |
| 4.3 | Statement values formatted | Values show as $X.XXB, $X.XXM, $X.XXK format. Missing values show "—". |
| 4.4 | Period headers show freshness tint | Headers <90 days: no tint. 90–365 days: amber. >365 days: red. |
| 4.5 | Restatement indicator shows | Restated statements display sync icon. Version badges show "v2", "v3", etc. |
| 4.6 | Research Context sidebar shows Freshness | Data as-of date, last filing date, freshness status badge (Fresh/Aging/Stale/Expired). |
| 4.7 | Coverage card shows quality scores | Overall score + 5 component bars (Historical, Completeness, Validation, Verification, Freshness). |
| 4.8 | Restatement card shows counts | Restated count and revised versions count display. |
| 4.9 | Next Steps card shows action | Open questions count, thesis freshness, and recommended next action display. |
| 4.10 | Sidebar collapses below 1200px | Below 1200px width, sidebar hides and "SHOW CONTEXT" toggle appears. |
| 4.11 | Sidebar toggle works | Clicking "SHOW CONTEXT"/"HIDE CONTEXT" toggles sidebar visibility. |

---

## 5. Settings

Navigate to Settings in main navigation.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 5.1 | Left navigation renders | Three sections: PROFILE, WORKSPACE, ACCOUNT with icons. |
| 5.2 | Active section highlighted | Selected section shows blue background and accent icon color. |
| 5.3 | Profile section shows username | Username and auto-generated email (username@taug.app) display. |
| 5.4 | Timezone dropdown works | Dropdown shows WIB, WITA, WIT, UTC, EST options. Selection persists. |
| 5.5 | Workspace density toggle works | Compact/Default chips toggle. Selected chip shows blue background. |
| 5.6 | Account section shows session info | Username, Version (1.0.0), Build (1), Platform (Web WASM) display. |
| 5.7 | Sign Out button works | Clicking "Log Out" signs out and redirects to login page. |

---

## 6. Portfolio Workspace

Navigate to Portfolio in main navigation.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 6.1 | Header shows position counts | Active count (blue), Review count (amber), Closed count (gray) badges display. |
| 6.2 | Tab bar shows 4 tabs | Active (X), Closed (X), Lessons, Patterns tabs render. |
| 6.3 | Active positions show P&L | Unrealized P&L percentage displays green (gain) or red (loss). |
| 6.4 | Active positions show days held | "Xd held" displays for each position. |
| 6.5 | Active positions show entry/current price | Entry price (@ $X.XX) and current price (Now: $X.XX) display when available. |
| 6.6 | Conviction badge renders | Low (gray), Medium (amber), High (blue) badges display. |
| 6.7 | Thesis title links to company | Thesis title shows with lightbulb icon when position has linked thesis. |
| 6.8 | Review Needed badge shows | Amber "Review Needed" badge displays on flagged positions. |
| 6.9 | Position popup menu works | Three-dot menu: View Company, Mark for Review, Close Position options. |
| 6.10 | Close Position dialog works | Outcome selector (Correct/Incorrect/Partial), exit price, lessons learned fields. |
| 6.11 | Closed positions show return % | Return percentage badge shows green (positive) or red (negative). |
| 6.12 | Closed positions show outcome badge | Correct (green), Incorrect (red), Partial (amber) badges display. |
| 6.13 | Closed positions show entry/exit dates | Both dates display in YYYY-MM-DD format. |
| 6.14 | Lessons tab groups by outcome | Three sections: "From Correct Decisions", "From Incorrect Decisions", "From Partial Decisions". |
| 6.15 | Lesson summary chips show counts | Correct/Incorrect/Partial counts with color-coded chips. |
| 6.16 | Lesson cards show stance + conviction | Each lesson displays stance badge, conviction badge, and lesson text. |
| 6.17 | "Apply to New Research" navigates | Button navigates to company's research workspace. |
| 6.18 | Patterns tab shows accuracy stats | Stance accuracy (Bullish/Bearish/Neutral), Conviction accuracy (High/Medium/Low) with percentages. |
| 6.19 | Patterns tab shows common lessons | Tag cloud of recurring lesson themes displays. |
| 6.20 | Patterns tab shows holding periods | Average holding days for correct vs incorrect positions. |
| 6.21 | Patterns tab shows overall win rate | Win rate percentage and partial count display. |
| 6.22 | Add Position dialog works | Company search, thesis selector, conviction chips, date picker, entry price, notes fields. |
| 6.23 | Pre-populated Add Position works | Navigating from thesis "Create Position" pre-fills company and thesis. |
| 6.24 | Empty states show guidance | Each tab shows contextual empty state with icon, title, and description. |

---

## 7. Questions (Cross-Feature)

Questions are created within Company Research but appear in Research Workspace.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 7.1 | Create question with priority | Company Research → Questions → "+" → enter text → select priority → Create. |
| 7.2 | Answer question with text | Click "Answer" → enter findings → "Mark Answered". Question moves to answered section. |
| 7.3 | Delete question with confirmation | Three-dot menu → Delete → confirmation dialog → Delete. |
| 7.4 | Questions appear in Research Workspace | Open questions from all companies appear in "Open Questions" section. |
| 7.5 | Critical questions trigger attention | Critical/high priority questions appear in "Needs Attention" hero. |

---

## 8. Lessons (Cross-Feature)

Lessons are captured when closing positions and appear in multiple places.

| # | Check | Expected Behavior |
|---|-------|-------------------|
| 8.1 | Lessons appear in thesis dialog | Opening thesis dialog for a company with closed positions shows "PRIOR LESSONS" section. |
| 8.2 | Prior lessons are collapsible | If >2 lessons, section collapses with "Show X more..." link. |
| 8.3 | "View all in Portfolio" link works | Link navigates to Portfolio Workspace when >3 lessons exist. |
| 8.4 | Lessons show outcome badges | Win (green), Loss (red), Partial (amber) badges with stance and conviction. |
| 8.5 | "Apply to New Research" navigates correctly | From Lessons tab, button goes to company's research page. |
| 8.6 | Patterns tab shows accuracy by stance | Bullish/Bearish/Neutral theses show correct/incorrect/partial breakdown. |
| 8.7 | Patterns tab shows accuracy by conviction | High/Medium/Low conviction shows correct/incorrect/partial breakdown. |

---

## Quick Smoke Test (5 minutes)

1. Login → verify redirect to main layout
2. Navigate to any company → Overview tab → verify Next Action banner
3. Switch to Research tab → verify progress checklist shows steps
4. Create a note → verify it appears in the list
5. Navigate to Research Workspace → verify the company appears in Active Research
6. Navigate to Portfolio → verify Add Position dialog opens
7. Navigate to Settings → verify Profile/Workspace/Account sections render
8. Sign Out → verify redirect to login page

---

*Last updated: 2026-06-22*
