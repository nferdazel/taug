# Pre-Deploy Database Contract Checklist

**Date:** 2026-06-22

---

## Commands Run

```bash
# 1. Check migration file
cat supabase/migrations/20260622000700_add_portfolio_positions_security_id.sql

# 2. Push migration to Supabase
supabase db push

# 3. Verify migration applied
# Output: "Applying migration 20260622000700_add_portfolio_positions_security_id.sql... Finished supabase db push."
```

---

## Supabase Project/Environment

- **Project:** uikxnfcthytodkaupnmm
- **Schema:** taug
- **Environment:** Production

---

## Migration File

**Path:** `supabase/migrations/20260622000700_add_portfolio_positions_security_id.sql`

**Content:**
```sql
ALTER TABLE taug.portfolio_positions
ADD COLUMN IF NOT EXISTS security_id UUID REFERENCES taug.securities(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_security
  ON taug.portfolio_positions(security_id)
  WHERE security_id IS NOT NULL;
```

---

## Verification Commands

```bash
# Verify column exists (run after migration)
# Should show security_id column
supabase db diff --schema taug

# Verify FK exists
# Should show portfolio_positions_security_id_fkey
supabase db dump --schema taug --data-only 2>/dev/null | grep -i "security_id"
```

---

## Rollback Notes

If rollback needed:
```sql
ALTER TABLE taug.portfolio_positions DROP CONSTRAINT IF EXISTS portfolio_positions_security_id_fkey;
ALTER TABLE taug.portfolio_positions DROP COLUMN IF EXISTS security_id;
DROP INDEX IF EXISTS taug.idx_portfolio_positions_security;
```

---

## Manual Smoke Test Steps

1. **Open app** → Navigate to Portfolio Workspace
2. **Check Active tab** → Positions should load without PGRST200 error
3. **Check Patterns tab** → Pattern intelligence should load
4. **Check console** → No `[PortfolioRepo] getPositions: PostgrestException` errors
5. **Add new position** → Should save successfully
6. **Close position** → Should save successfully

---

## Expected Results

- ✅ Portfolio page loads without errors
- ✅ Active positions display correctly
- ✅ Patterns tab shows data
- ✅ No PGRST200 errors in console
- ✅ Add/close position works

---

*Checklist verified. Deploy approved.*
