# TAUG Closed Beta — Deployment Readiness Checklist

**Date:** 2026-06-22
**Audience:** Project Owner, DevOps
**Status:** Pre-deployment gate

---

## 1. Vercel Environment Variables

Set in Vercel Dashboard → Settings → Environment Variables.

- [ ] `SUPABASE_URL` — Supabase project URL
- [ ] `SUPABASE_ANON_KEY` — Supabase anon/public key
- [ ] `TWELVE_DATA_API_KEY` — Twelve Data market API
- [ ] `FRED_API_KEY` — Federal Reserve Economic Data
- [ ] `BPS_API_KEY` — BPS macro data
- [ ] `SEC_USER_AGENT` — SEC EDGAR user agent string
- [ ] `VERCEL_TOKEN` — Vercel deploy token (CI only)
- [ ] `VERCEL_PROJECT_ID` — Vercel project ID (CI only)
- [ ] `VERCEL_ORG_ID` — Vercel org ID (CI only)

**Verify:** Run `vercel env ls` to confirm all variables are set.

---

## 2. Supabase Environment Variables

Set in Supabase Dashboard → Edge Functions → Secrets.

- [ ] `SUPABASE_URL` — Project URL
- [ ] `SUPABASE_SERVICE_ROLE_KEY` — Service role key (server-side only)
- [ ] `TWELVE_DATA_API_KEY` — Twelve Data API
- [ ] `FRED_API_KEY` — FRED API
- [ ] `BPS_API_KEY` — BPS API
- [ ] `SEC_USER_AGENT` — SEC EDGAR user agent
- [ ] `RAW_DOCUMENTS_BUCKET` — Storage bucket name (`raw-documents`)

**Verify:** Run `supabase secrets list` to confirm all secrets are set.

---

## 3. API Key Rotation

All keys must be rotated before beta. Old keys must be invalidated.

- [ ] Supabase service role key rotated
- [ ] Twelve Data API key rotated
- [ ] FRED API key rotated
- [ ] BPS API key rotated

**Action:** After rotation, update both Vercel AND Supabase secrets.

---

## 4. Database Migrations

40 migrations in `supabase/migrations/`. All must be applied.

- [ ] All migrations applied (`supabase db push` or `supabase migration up`)
- [ ] RLS policies verified (no open access)
- [ ] Service role permissions granted (migration `20260622000800`)
- [ ] Auth trigger working (migration `20250101000000`)

**Verify:** Run `supabase db diff` to confirm no pending migrations.

---

## 5. Edge Functions

7 functions deployed via `supabase functions deploy`.

- [ ] `get-chart-data` deployed
- [ ] `get-price` deployed
- [ ] `refresh-calendar` deployed
- [ ] `refresh-news` deployed
- [ ] `refresh-policy` deployed
- [ ] `refresh-quote-snapshots` deployed
- [ ] `search-symbols` deployed

**Verify:** Run `supabase functions list` to confirm all functions are live.

---

## 6. Security Verification

- [ ] `.env` NOT in git (confirmed in `.gitignore`)
- [ ] `env.g.dart` NOT in git (confirmed in `.gitignore`)
- [ ] CSP headers correct in `vercel.json`
- [ ] No hardcoded API keys in source
- [ ] Schema isolation: app uses `taug` schema (not `public`)
- [ ] Error messages sanitized (no PII in production)

---

## 7. Rollback Plan

### Vercel Rollback
1. Open Vercel Dashboard → Deployments
2. Find last known-good deployment
3. Click "..." → "Promote to Production"

### Database Rollback
1. Identify affected migration
2. Write rollback SQL (if destructive)
3. Apply via `supabase db reset` or manual SQL

### Edge Function Rollback
1. Re-deploy previous function version
2. Verify function health

**Notify:** Inform beta users of any rollback via email/Discord.

---

## 8. Monitoring Checks

- [ ] Supabase Dashboard accessible (Database, Auth, Edge Functions)
- [ ] Vercel Dashboard accessible (Deployments, Analytics)
- [ ] GitHub Actions running (CI/CD pipeline)
- [ ] Error logging active (Edge Function logs)
- [ ] Database connection pool healthy

---

## 9. Smoke Test Checklist

Test after deploy. All must pass before opening beta.

### Core App
- [ ] App loads without errors (WASM build)
- [ ] No console errors on load
- [ ] Login works (username + password)
- [ ] Register works (new account)

### Pages
- [ ] Companies page loads
- [ ] Company workspace loads (Overview, Financials, Research)
- [ ] Research tab works (questions, thesis, notes)
- [ ] Portfolio tab works (active, closed, lessons)
- [ ] Settings page loads

### Data
- [ ] No PGRST200 errors (schema/RLS issues)
- [ ] Price data loads (Twelve Data)
- [ ] News feed loads (RSS)
- [ ] Calendar events load

### Performance
- [ ] Page load < 3 seconds
- [ ] No layout shifts on load
- [ ] Scrolling is smooth (60fps)

---

## 10. Pre-Beta Gate

**All items above must be checked before opening beta.**

| Category | Required | Status |
|---|---|---|
| Vercel Env Vars | 9/9 set | — |
| Supabase Secrets | 7/7 set | — |
| API Key Rotation | 4/4 rotated | — |
| DB Migrations | 40/40 applied | — |
| Edge Functions | 7/7 deployed | — |
| Security | 6/6 verified | — |
| Monitoring | 5/5 active | — |
| Smoke Tests | 12/12 passed | — |

---

*Checklist complete = Beta go. No shortcuts.*
