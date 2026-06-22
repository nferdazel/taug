-- Phase 4: Backfill security_id bridge columns from symbol_id
--
-- PURPOSE: Begin the symbols → securities transition by populating the
-- security_id bridge columns that were added by 20260619000500 but remain NULL.
--
-- MATCHING STRATEGY: ticker-only
--
-- NOTE: This backfill intentionally uses ticker-only matching.
-- Securities currently do not have exchange_id populated consistently
-- (SEC pipeline creates securities with exchange_id = NULL).
-- Upgrade to ticker + exchange matching once canonical securities
-- become exchange-aware.
--
-- COLLISION RISK: Zero collisions detected in current data.
-- 46 symbols, 10 securities, 7 ticker overlap, 0 same-ticker-different-exchange.
--
-- SCOPE: Backfill only. No tables dropped. No columns removed.
-- No application code changes. No worker changes.
-- symbols table is NOT deprecated. Both identity systems coexist.

-- Backfill watchlist_items.security_id
UPDATE taug.watchlist_items wi
SET security_id = s.id
FROM taug.securities s
JOIN taug.symbols sym ON sym.ticker = s.ticker
WHERE wi.symbol_id = sym.id
  AND wi.security_id IS NULL;

-- Backfill portfolio_holdings.security_id
UPDATE taug.portfolio_holdings ph
SET security_id = s.id
FROM taug.securities s
JOIN taug.symbols sym ON sym.ticker = s.ticker
WHERE ph.symbol_id = sym.id
  AND ph.security_id IS NULL;

-- Backfill alerts.security_id
UPDATE taug.alerts a
SET security_id = s.id
FROM taug.securities s
JOIN taug.symbols sym ON sym.ticker = s.ticker
WHERE a.symbol_id = sym.id
  AND a.security_id IS NULL;

-- Verification queries (run after migration):
--
-- 1. Match counts per table:
--    SELECT 'watchlist_items' AS tbl,
--           COUNT(*) AS total,
--           COUNT(security_id) AS bridged,
--           COUNT(*) - COUNT(security_id) AS unmatched
--    FROM taug.watchlist_items
--    UNION ALL
--    SELECT 'portfolio_holdings',
--           COUNT(*), COUNT(security_id), COUNT(*) - COUNT(security_id)
--    FROM taug.portfolio_holdings
--    UNION ALL
--    SELECT 'alerts',
--           COUNT(*), COUNT(security_id), COUNT(*) - COUNT(security_id)
--    FROM taug.alerts;
--
-- 2. Collision check (should be 0):
--    SELECT sym.ticker, COUNT(DISTINCT s.id) AS security_count
--    FROM taug.symbols sym
--    JOIN taug.securities s ON s.ticker = sym.ticker
--    GROUP BY sym.ticker
--    HAVING COUNT(DISTINCT s.id) > 1;
