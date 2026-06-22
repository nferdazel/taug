# TAUG — Workflow Architecture

## User Journey

```
Open TAUG
→ Browse Companies
→ Open Company Workspace
→ Research Company
→ Write Thesis
→ Create Position
→ Monitor Decision
→ Close Position
→ Record Outcome
→ Learn From History
```

---

## Research Lifecycle

### Stage 1: Discover

**User intent:** "What companies should I research?"

**Entry points:**
- Companies Workspace (browse all)
- Screener (filter by metrics)
- Research Workspace (existing research)

**Artifacts created:** None (discovery only)

### Stage 2: Research

**User intent:** "What do I think about this company?"

**Entry point:** Company Workspace

**Activities:**
- Read financial statements
- Review key metrics
- Read existing notes
- Create new notes
- Assess data quality

**Artifacts created:** Research notes

### Stage 3: Thesis

**User intent:** "What's my investment thesis?"

**Entry point:** Company Workspace → Research tab

**Activities:**
- Write thesis summary
- Define bull case
- Define bear case
- Set conviction level

**Artifacts created:** Investment thesis

### Stage 4: Decision

**User intent:** "Should I invest?"

**Entry point:** Company Workspace → Research tab → Thesis

**Activities:**
- Review thesis
- Assess conviction
- Decide to invest or pass

**Artifacts created:** Position (if investing) or closed thesis (if passing)

### Stage 5: Portfolio

**User intent:** "What decisions have I made?"

**Entry point:** Portfolio Workspace

**Activities:**
- Review active positions
- Monitor conviction
- Identify positions needing review

**Artifacts created:** Position records

### Stage 6: Outcome

**User intent:** "What happened?"

**Entry point:** Portfolio Workspace → Close Position

**Activities:**
- Record outcome (correct/incorrect/partial)
- Record lessons learned
- Close position

**Artifacts created:** Closed position with outcome

### Stage 7: Learning

**User intent:** "What did I learn?"

**Entry point:** Portfolio Workspace → Closed tab

**Activities:**
- Review past decisions
- Identify patterns
- Improve future research

**Artifacts created:** None (learning is internal)

---

## Thesis Lifecycle

```
Draft → Active → Reviewing → Updated → Closed
```

| State | Meaning | Trigger |
|---|---|---|
| Draft | Thesis being written | User creates thesis |
| Active | Thesis is current | User saves thesis |
| Reviewing | Thesis needs attention | Manual or stale detection |
| Updated | Thesis has been revised | User edits thesis |
| Closed | Thesis is complete | Position closed or thesis invalidated |

---

## Portfolio Lifecycle

```
Research → Thesis → Position → Monitoring → Review → Closed → Learning
```

| State | Meaning | Trigger |
|---|---|---|
| Active | Position is held | User creates position |
| Review Needed | Thesis needs attention | Manual or automated detection |
| Closed | Position exited | User closes position |

---

## Learning Lifecycle

```
Decision → Outcome → Recording → Pattern Recognition → Improvement
```

| Stage | Activity | Artifact |
|---|---|---|
| Decision | User makes investment | Position record |
| Outcome | Position result known | Outcome (correct/incorrect/partial) |
| Recording | User records lessons | Lessons learned text |
| Pattern Recognition | User reviews past decisions | Closed positions history |
| Improvement | User applies learnings | Better future decisions |

---

## Expected User Behavior

### Daily Use
- Open TAUG
- Check Research Workspace for companies needing attention
- Review thesis status
- Create/update notes

### Weekly Use
- Review Portfolio Workspace
- Check positions needing review
- Update conviction if needed
- Create new theses

### Monthly Use
- Review closed positions
- Identify learning patterns
- Adjust research approach
- Update watchlists

### Ad-hoc Use
- Discover new companies via screener
- Deep-dive research on specific companies
- Create positions when conviction is high
- Close positions when thesis is invalidated
