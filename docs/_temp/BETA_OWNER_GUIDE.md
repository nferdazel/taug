# TAUG Beta Owner Guide

**Date:** 2026-06-22
**Audience:** Project Owner
**Reading Time:** 5 minutes

---

## 1. Executive Summary

TAUG is ready for closed beta. The Research OS MVP is complete, runtime verified, testing hardened, and code quality gated.

**Goal:** Learn from real users. Not adoption — learning.

---

## 2. Beta Goals

1. **Validate workflow** — Does Research → Thesis → Decision → Portfolio → Outcome → Learning work?
2. **Identify friction** — Where do users get stuck?
3. **Measure trust** — Do users trust the data?
4. **Discover gaps** — What's missing that users need?
5. **Test assumptions** — Is TAUG a Research OS or a data viewer?

---

## 3. Recommended Beta Users

**Profile:** Long-term equity investors, research-oriented, desktop users.

**Ideal Users:**
1. **The Researcher** — Deep dives into companies before investing
2. **The Decision Maker** — Forms theses and tracks decisions
3. **The Learner** — Reviews past decisions to improve
4. **The Skeptic** — Questions everything, needs data trust
5. **The Newcomer** — Fresh eyes, tests onboarding

**Avoid:**
- Day traders (not target user)
- Mobile-only users (desktop-first)
- Passive investors (not research-oriented)

---

## 4. Success Metrics

### Core Metrics

| Metric | Target |
|---|---|
| Research Created | 3+ companies per user |
| Thesis Created | 1+ per user |
| Questions Created | 2+ per user |
| Notes Created | 5+ per user |
| Positions Created | 1+ per user |
| Lessons Created | 1+ per user |

### Engagement Metrics

| Metric | Target |
|---|---|
| Time to First Thesis | < 30 min |
| Time to First Position | < 60 min |
| Return Sessions | 3+ in first week |

### Failure Signals

| Signal | Action |
|---|---|
| User stuck 5+ min | Check UX |
| User abandons workflow | Check friction |
| User never reaches thesis | Check onboarding |
| User never returns | Check value proposition |

---

## 5. Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Users don't return | Medium | High | Improve onboarding |
| Users don't create theses | Medium | High | Simplify thesis form |
| Users don't trust data | Medium | Medium | Improve data quality visibility |
| Users find bugs | High | Medium | Quick hotfix process |
| Users want features not built | High | Low | Document as future work |

---

## 6. Deployment Checklist Summary

**Before Deploy:**
- [ ] Rotate API keys
- [ ] Verify all migrations applied
- [ ] Verify RLS policies
- [ ] Run smoke test
- [ ] Verify Vercel env vars

**After Deploy:**
- [ ] Smoke test production
- [ ] Monitor error logs
- [ ] Check Supabase dashboard
- [ ] Check Vercel dashboard

---

## 7. First Week Plan

### Day 1: Deploy
- Deploy to Vercel
- Run smoke test
- Monitor for errors

### Day 2: Invite Users
- Send welcome email with quick start guide
- Create user accounts
- Monitor first sessions

### Day 3-5: Observe
- Check engagement metrics
- Monitor failure signals
- Collect initial feedback

### Day 6-7: Review
- Review feedback forms
- Identify top issues
- Plan fixes

---

## 8. Go / No-Go Recommendation

# B. Deploy for Closed Beta

**Rationale:**

1. **Research OS MVP complete.** Core workflow (Research → Thesis → Decision → Portfolio → Outcome → Learning) is functional.

2. **Runtime verified.** PGRST200 fixed. All queries pass against live Supabase.

3. **Testing hardened.** 375 tests passing. Widget tests exist.

4. **Code quality gated.** All critical and high issues fixed.

5. **Feedback system ready.** Template, metrics, test plan all prepared.

**What's NOT perfect:**
- Testing at 7/10 (not 8/10)
- Accessibility at 7/10 (not 8/10)
- Some deferred issues remain

**Why Deploy Anyway:**
- Beta is for learning, not perfection
- Real user feedback > internal testing
- Core workflow is solid
- Quick hotfix process in place

**Next Steps:**
1. Deploy to Vercel
2. Invite 2-5 users
3. Collect feedback for 2 weeks
4. Iterate based on learning

---

*Deploy. Learn. Iterate.*
