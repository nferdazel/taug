from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from hashlib import sha256
from typing import Any

from ..http_client import HttpClient
from ..supabase_rest import SupabaseRestClient


FRED_API_BASE: str = "https://api.stlouisfed.org/fred"
DEFAULT_SERIES: tuple[str, ...] = (
  "DFF",
  "CPIAUCSL",
  "UNRATE",
  "GDP",
  "DGS10",
)


@dataclass(frozen=True)
class FredSyncSummary:
  processed_series: int
  succeeded: int
  failed: int
  inserted_observations: int
  failed_series_ids: tuple[str, ...]


def run_sync_fred_series(
  *,
  supabase_client: SupabaseRestClient,
  http_client: HttpClient,
  fred_api_key: str,
  series_ids: tuple[str, ...] | None = None,
  limit: int = 0,
) -> FredSyncSummary:
  if not fred_api_key:
    raise ValueError("FRED_API_KEY is required")

  target_series: tuple[str, ...] = series_ids or DEFAULT_SERIES
  if limit > 0:
    target_series = target_series[:limit]

  source = supabase_client.ensure_raw_source(
    code="fred",
    name="Federal Reserve Economic Data",
    source_type="api",
    region="US",
    is_official=True,
  )

  succeeded = 0
  failed = 0
  inserted = 0
  failed_ids: list[str] = []

  for series_id in target_series:
    try:
      count = _sync_one_series(
        supabase_client=supabase_client,
        http_client=http_client,
        fred_api_key=fred_api_key,
        series_id=series_id,
        raw_source_id=source.id,
      )
      succeeded += 1
      inserted += count
    except Exception:
      failed += 1
      failed_ids.append(series_id)

  return FredSyncSummary(
    processed_series=len(target_series),
    succeeded=succeeded,
    failed=failed,
    inserted_observations=inserted,
    failed_series_ids=tuple(failed_ids),
  )


def _sync_one_series(
  *,
  supabase_client: SupabaseRestClient,
  http_client: HttpClient,
  fred_api_key: str,
  series_id: str,
  raw_source_id: int,
) -> int:
  response = http_client.request(
    "GET",
    f"{FRED_API_BASE}/series/observations",
    query={
      "series_id": series_id,
      "api_key": fred_api_key,
      "file_type": "json",
      "sort_order": "desc",
      "limit": "100",
    },
    timeout_seconds=30,
  )
  if response.status_code != 200:
    raise ValueError(
      f"FRED API error for {series_id}: status={response.status_code}"
    )

  data = response.json()
  if not isinstance(data, dict):
    raise ValueError(f"FRED API returned non-dict for {series_id}")

  observations: list[dict[str, object]] = data.get("observations", [])
  if not isinstance(observations, list):
    raise ValueError(f"FRED API returned non-list observations for {series_id}")

  payload_bytes: bytes = response.body
  content_hash: str = sha256(payload_bytes).hexdigest()
  source_record_key: str = f"fred_observations:{series_id}"

  existing_raw = supabase_client.find_raw_record_by_key(
    source_record_key=source_record_key,
  )

  if existing_raw is None:
    supabase_client.insert_raw_record_simple(
      raw_source_id=raw_source_id,
      record_type="fred_observations",
      source_record_key=source_record_key,
      source_entity_key=series_id,
      payload_json=data,
      payload_hash=content_hash,
      schema_version="1",
    )
  else:
    supabase_client.update_raw_record_payload(
      record_id=existing_raw[0],
      payload_json=data,
      payload_hash=content_hash,
    )

  _upsert_series_metadata(supabase_client, series_id, data)

  inserted: int = 0
  for obs in observations:
    if not isinstance(obs, dict):
      continue
    obs_date: object = obs.get("date")
    obs_value: object = obs.get("value")
    if not isinstance(obs_date, str):
      continue

    numeric_value: float | None = None
    if isinstance(obs_value, str) and obs_value.strip() != ".":
      try:
        numeric_value = float(obs_value)
      except ValueError:
        numeric_value = None

    result = supabase_client.upsert_macro_observation(
      series_id=series_id,
      observation_date=obs_date[:10],
      value_numeric=numeric_value,
    )
    if result.created:
      inserted += 1

  supabase_client.update_macro_series_fetched(series_id)

  return inserted


def _upsert_series_metadata(
  supabase_client: SupabaseRestClient,
  series_id: str,
  data: dict[str, object],
) -> None:
  series_info: object = data.get("seriess")
  if not isinstance(series_info, list) or not series_info:
    return

  info: object = series_info[0]
  if not isinstance(info, dict):
    return

  title: str = str(info.get("title", series_id))
  frequency: str = str(info.get("frequency", ""))
  units: str = str(info.get("units", ""))

  category: str = "other"
  title_lower = title.lower()
  if "rate" in title_lower or "interest" in title_lower or "fund" in title_lower:
    category = "interest_rate"
  elif "cpi" in title_lower or "inflation" in title_lower or "price index" in title_lower:
    category = "inflation"
  elif "unemploy" in title_lower or "labor" in title_lower or "job" in title_lower:
    category = "employment"
  elif "gdp" in title_lower or "gross domestic" in title_lower:
    category = "gdp"
  elif "trade" in title_lower or "export" in title_lower or "import" in title_lower:
    category = "trade"

  supabase_client.upsert_macro_series(
    series_id=series_id,
    title=title,
    category=category,
    frequency=frequency,
    units=units,
  )
