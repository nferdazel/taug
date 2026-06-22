# TAUG Disagreement Log

**Date:** 2026-06-22
**Purpose:** Record all significant disagreements. Healthy teams disagree.

---

## Disagreement 1: Where Lessons Should Appear During Thesis Creation

**Issue:** Where should prior lessons be surfaced when creating a new thesis?

**Position A (UX Agent):**
- Inline collapsible section at top of thesis dialog
- Context where decisions are made
- One glance away from thesis creation
- Keeps dialog clean (collapsible)

**Position B (God-3):**
- Sidebar panel next to thesis dialog
- Persistent visibility
- Doesn't add height to dialog

**Reviewer Position:** Supported Position A. "The thesis dialog is where users formalize their investment thesis. This is the moment of maximum receptivity to prior lessons."

**Final Resolution:** Accepted Position A (inline collapsible section)

**Lessons Learned:**
- Context where decisions are made is more important than persistent visibility
- Collapsible sections balance density and cleanliness
- Dialog height is acceptable for research workflow

---

## Disagreement 2: How Patterns Should Be Surfaced

**Issue:** How should lesson patterns be presented to users?

**Position A (UX Agent):**
- Micro-summaries (inline text, 1-2 lines)
- Dense information, no decoration
- Consistent with terminal aesthetic

**Position B (Designer):**
- Mini-charts (sparklines, bar charts)
- Visual appeal
- Easier to comprehend at a glance

**Reviewer Position:** Supported Position A. "Financial terminals prioritize density over decoration. Micro-summaries deliver insight without cognitive overhead."

**Final Resolution:** Accepted Position A (micro-summaries)

**Lessons Learned:**
- Density over decoration is a core design principle
- Charts add complexity without proportional insight
- Text-based patterns are sufficient for research workflow

---

## Disagreement 3: Should TAUG Monitor Metrics Actively or Passively?

**Issue:** Should invalidation conditions be monitored actively (polling) or passively (view-based)?

**Position A (God-3):**
- Passive monitoring in MVP (view-based)
- No new infrastructure
- No API costs
- User sees breaches when they visit thesis

**Position B (Backend-1):**
- Active polling (Edge Function on cron)
- Proactive alerts
- User never misses breaches

**Reviewer Position:** Supported Position A. "Passive monitoring is sufficient for MVP. Can upgrade to active later if users request it."

**Final Resolution:** Accepted Position A (passive monitoring)

**Lessons Learned:**
- MVP should minimize infrastructure
- Passive monitoring validates approach before deeper investment
- User feedback will determine if active monitoring is needed

---

## Disagreement 4: How to Track Thesis Evolution

**Issue:** How should changes to a thesis over time be tracked?

**Position A (God-3):**
- Changelog in `metadata` JSONB
- Append-only log of field changes
- No new tables needed

**Position B (Data-1):**
- Formal `research_reviews` table
- Explicit "I reviewed this today" actions
- Richer audit trail

**Reviewer Position:** Supported both. "Changelog for field changes, reviews for explicit review actions. Both are complementary."

**Final Resolution:** Accepted both (changelog + reviews table)

**Lessons Learned:**
- Different mechanisms serve different purposes
- Changelog tracks implicit changes
- Reviews track explicit actions
- Both are needed for complete audit trail

---

## Disagreement 5: MVP Scope for Research Intelligence

**Issue:** How much of the research intelligence design should ship in the first iteration?

**Position A (Build Orchestrator):**
- P0 only (expose fields, freshness, Mark Reviewed)
- 1 migration + 9 file modifications
- No new tables (except `last_reviewed_at`)
- Can validate with users before building more

**Position B (God-3):**
- P0 + P1 (add Questions, Assumptions, Conditions)
- More complete intelligence system
- Ships as a cohesive feature

**Reviewer Position:** Supported Position A. "Ship incrementally. Validate approach before deeper investment."

**Final Resolution:** Accepted Position A (P0 only)

**Lessons Learned:**
- Incremental shipping reduces risk
- User feedback shapes next iteration
- 60% of perceived intelligence upgrade from P0 alone
- P1 can be built after P0 is validated

---

*This log is continuously updated throughout execution. If it remains empty, the review process is likely ineffective.*
