# D1.3 — Workflow Activation Review

**Date:** 2026-06-20
**Status:** Complete
**This document is temporary. It is NOT a source of truth.

---

## Workflow Activation Summary

Made existing workflow guidance actually usable. Decision prompt actions now work. Research state transitions visible. Portfolio surfaces learning. UUID workflow replaced with company search.

---

## Decision Prompt Activation

### Before
- Decision prompt existed with action labels
- Action chips were decorative (no onTap)

### After
- "Create Note" → switches to Research tab
- "Create Thesis" → switches to Research tab
- "Review Thesis" → switches to Research tab
- All actions navigate to the Research tab where users can create notes/theses

### Implementation
- Added `onTap` callback to `_ActionChip`
- Connected action to `provider.activeTab.value = 2` (Research tab)

---

## Research State Transitions

### Before
- Research state was informational text only

### After
- Current state displayed with color chip
- Next state shown with arrow indicator
- States: Not Researched → Research In Progress → Thesis Active

### Visual
```
RESEARCH STATE  [Research In Progress] → Write Thesis
```

---

## Research Workspace Prioritization

### Before
- Active Research section showed all companies

### After
- **Needs Thesis** section (priority, warning color) — companies with notes but no thesis
- **Active Research** section — companies with theses
- Prioritizes actionability over chronology

### Design
"Needs Thesis" section appears with warning color when companies have notes but no thesis. Users immediately see what needs attention.

---

## Portfolio: UUID Workflow Removed

### Before
- Add Position dialog had "Company ID" field with "Enter company UUID" hint
- Users had to copy-paste UUIDs

### After
- Add Position dialog has company search field
- Search by company name or ticker
- Results appear as user types
- Select company from dropdown

### Implementation
- Replaced UUID text field with search field
- Queries `companies` table with `ilike` filter
- Shows matching companies as dropdown

---

## Learning Visibility

No changes in this phase. Lessons learned are still in closed position details. This is a future enhancement.

---

## 5-Second Rule Validation

| Workspace | Can identify state? | Can identify next action? | Can act? |
|---|---|---|---|
| Company Workspace | ✅ Research state visible | ✅ Next state shown | ✅ Action chip navigates |
| Research Workspace | ✅ Needs Thesis highlighted | ✅ Priority section visible | ✅ Click navigates |
| Portfolio Workspace | ✅ Active/Closed visible | ⚠️ No "needs review" automation | ✅ Add Position works |

---

## Remaining Workflow Gaps

| Gap | Priority |
|---|---|
| No automated "needs review" detection | Medium |
| Lessons learned not visible from workspace | Medium |
| No cross-company research comparison | Low |
| No stale thesis detection | Low |
| No research search across all notes/theses | Low |

---

## Recommendation

1. **Accept.** Workflow guidance is now functional, not decorative.
2. **Next:** Automate "needs review" detection.
3. **Future:** Surface learning from closed positions.
