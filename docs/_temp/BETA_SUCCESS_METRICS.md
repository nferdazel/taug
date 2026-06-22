# TAUG Beta Success Metrics

## Purpose

Define what success means for the closed beta. Focus on product learning, not vanity metrics. Track what matters for Research OS.

---

## Core Metrics (Research Activity)

| Metric | Description | Target |
|---|---|---|
| Research Created | Number of companies researched | 3+ per user |
| Thesis Created | Number of theses written | 1+ per user |
| Questions Created | Number of research questions | 2+ per user |
| Notes Created | Number of research notes | 5+ per user |
| Positions Created | Number of positions added | 1+ per user |
| Lessons Created | Number of lessons recorded | 1+ per user |

---

## Engagement Metrics

| Metric | Description | Target |
|---|---|---|
| Time to First Thesis | Minutes from first login to first thesis | < 30 min |
| Time to First Position | Minutes from first login to first position | < 60 min |
| Return Sessions | Number of sessions in first week | 3+ |
| Session Duration | Average minutes per session | 10+ min |

---

## Failure Signals

| Signal | Description | Action |
|---|---|---|
| User stuck | No action for 5+ minutes | Check UX |
| User abandons workflow | Exits mid-workflow | Check friction |
| User never reaches thesis | No thesis after 2 sessions | Check onboarding |
| User never returns | Single session only | Check value proposition |

---

## Quality Metrics

| Metric | Description | Target |
|---|---|---|
| Thesis Completeness | Average fields filled per thesis | 6+ of 10 |
| Question Quality | Average questions per company | 2+ |
| Lesson Quality | Average words per lesson | 20+ |

---

## Measurement Strategy

### Data Collection
- Track all events via Supabase `analytics_events` table
- Session tracking via `session_start` and `session_end` events
- Workflow tracking via `workflow_start`, `workflow_step`, and `workflow_complete` events

### Analysis Cadence
- Daily: Check failure signals
- Weekly: Review engagement metrics
- Bi-weekly: Analyze research activity and quality metrics

### Success Criteria
- **Minimum Viable Beta**: 5+ users complete at least 1 thesis
- **Good Beta**: 80% of users create 2+ theses
- **Excellent Beta**: 60% of users return for 3+ sessions

---

## Constraints

- Focus on product learning, not vanity metrics
- Track what matters for Research OS
- Simple to measure
- No complex analytics infrastructure required

---

## Next Steps

1. Implement event tracking in Supabase
2. Create dashboard for monitoring metrics
3. Set up alerts for failure signals
4. Schedule weekly review cadence