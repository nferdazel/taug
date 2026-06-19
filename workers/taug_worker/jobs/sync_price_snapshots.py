from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import time

from ..http_client import HttpClient
from ..supabase_rest import SupabaseRestClient


TEN_DELAY: float = 12.0  # Twelve Data free tier: 8 req/min


@dataclass(frozen=True)
class PriceSyncSummary:
  processed_securities: int
  succeeded: int
  failed: int
  inserted: int
  failed_tickers: tuple[str, ...]


def run_sync_price_snapshots(
  *,
  supabase_client: SupabaseRestClient,
  http_client: HttpClient,
  twelve_data_api_key: str,
  limit: int = 0,
) -> PriceSyncSummary:
  if not twelve_data_api_key:
    raise ValueError("TWELVE_DATA_API_KEY is required")

  securities = supabase_client.list_securities_with_tickers(limit=limit)
  if not securities:
    return PriceSyncSummary(
      processed_securities=0,
      succeeded=0,
      failed=0,
      inserted=0,
      failed_tickers=(),
    )

  succeeded = 0
  failed = 0
  inserted = 0
  failed_tickers: list[str] = []

  for i, (security_id, ticker) in enumerate(securities):
    if i > 0:
      time.sleep(TEN_DELAY)

    try:
      quote = _fetch_quote(http_client, ticker, twelve_data_api_key)
      if quote is None:
        failed += 1
        failed_tickers.append(ticker)
        continue

      result = supabase_client.upsert_price_snapshot(
        security_id=security_id,
        ticker=ticker,
        close_price=quote.get("close"),
        market_cap=None,
        enterprise_value=None,
        shares_outstanding=None,
        price_date=quote.get("date", datetime.now(timezone.utc).strftime("%Y-%m-%d")),
      )
      if result.created:
        inserted += 1
      succeeded += 1
    except Exception:
      failed += 1
      failed_tickers.append(ticker)

  return PriceSyncSummary(
    processed_securities=len(securities),
    succeeded=succeeded,
    failed=failed,
    inserted=inserted,
    failed_tickers=tuple(failed_tickers),
  )


def _fetch_quote(
  http_client: HttpClient,
  ticker: str,
  api_key: str,
) -> dict[str, object] | None:
  response = http_client.request(
    "GET",
    "https://api.twelvedata.com/quote",
    query={
      "symbol": ticker,
      "apikey": api_key,
    },
    timeout_seconds=15,
  )
  if response.status_code == 429:
    raise ValueError(f"Twelve Data API rate limit exceeded for {ticker}")
  if response.status_code != 200:
    return None

  try:
    data = response.json()
  except Exception:
    return None

  if not isinstance(data, dict):
    return None
  if "code" in data:
    return None

  return data
