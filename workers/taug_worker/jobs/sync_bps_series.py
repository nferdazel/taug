from __future__ import annotations

import time
from dataclasses import dataclass
from datetime import datetime, timezone
from hashlib import sha256
from typing import Any

from ..http_client import HttpClient
from ..supabase_rest import SupabaseRestClient


BPS_API_BASE: str = "https://webapi.bps.go.id/v1/api"
BPS_DOMAIN_NATIONAL: str = "0000"
BPS_REQUEST_DELAY: float = 2.0
BPS_MAX_RETRIES: int = 3
BPS_RETRY_DELAY: float = 15.0
BPS_HEADERS: dict[str, str] = {
  "Accept": "application/json",
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept-Language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7",
}

# Curated BPS macro variables for national Indonesia data
# These are variable IDs from BPS dynamic tables (domain 0000 = national)
# Verified against live BPS API on 2026-06-20
BPS_MACRO_VARIABLES: tuple[dict[str, str], ...] = (
  {"var_id": "8", "title": "GDP by Industrial Origin (Billion IDR)", "category": "gdp", "unit": "Billion IDR"},
  {"var_id": "9", "title": "GDP Growth Rate by Industrial Origin (Percent)", "category": "gdp", "unit": "Percent"},
  {"var_id": "2", "title": "Consumer Price Index (General)", "category": "inflation", "unit": "Index"},
  {"var_id": "1", "title": "Month-to-Month Inflation (Percent)", "category": "inflation", "unit": "Percent"},
)


@dataclass(frozen=True)
class BpsSyncSummary:
  processed_variables: int
  succeeded: int
  failed: int
  inserted_observations: int
  failed_var_ids: tuple[str, ...]


def run_sync_bps_series(
  *,
  supabase_client: SupabaseRestClient,
  http_client: HttpClient,
  bps_api_key: str,
  variable_ids: tuple[dict[str, str], ...] | None = None,
) -> BpsSyncSummary:
  if not bps_api_key:
    raise ValueError("BPS_API_KEY is required")

  target_vars: tuple[dict[str, str], ...] = variable_ids or BPS_MACRO_VARIABLES

  source = supabase_client.ensure_raw_source(
    code="bps",
    name="Badan Pusat Statistik",
    source_type="api",
    region="ID",
    is_official=True,
    access_method="https_api",
  )

  succeeded = 0
  failed = 0
  inserted = 0
  failed_ids: list[str] = []

  for var_def in target_vars:
    var_id: str = var_def["var_id"]
    title: str = var_def["title"]
    category: str = var_def["category"]
    unit: str = var_def["unit"]

    try:
      count = _sync_one_variable(
        supabase_client=supabase_client,
        http_client=http_client,
        bps_api_key=bps_api_key,
        var_id=var_id,
        title=title,
        category=category,
        unit=unit,
        raw_source_id=source.id,
      )
      succeeded += 1
      inserted += count
    except Exception:
      failed += 1
      failed_ids.append(var_id)

    time.sleep(BPS_REQUEST_DELAY)

  return BpsSyncSummary(
    processed_variables=len(target_vars),
    succeeded=succeeded,
    failed=failed,
    inserted_observations=inserted,
    failed_var_ids=tuple(failed_ids),
  )


def _sync_one_variable(
  *,
  supabase_client: SupabaseRestClient,
  http_client: HttpClient,
  bps_api_key: str,
  var_id: str,
  title: str,
  category: str,
  unit: str,
  raw_source_id: int,
) -> int:
  series_id: str = f"bps_{var_id}"

  year_ids = _fetch_year_ids(
    http_client=http_client,
    bps_api_key=bps_api_key,
    var_id=var_id,
  )
  if not year_ids:
    return 0

  all_observations: list[tuple[str, float]] = []
  for batch_start in range(0, len(year_ids), 3):
    batch = year_ids[batch_start:batch_start + 3]
    year_param: str = ";".join(batch)

    data: dict[str, object] = _bps_api_request(
      http_client=http_client,
      bps_api_key=bps_api_key,
      endpoint="list",
      params={
        "model": "data",
        "domain": BPS_DOMAIN_NATIONAL,
        "var": var_id,
        "th": year_param,
        "lang": "eng",
      },
    )

    if data.get("status") != "OK":
      continue

    tahun_list: list[dict[str, object]] = data.get("tahun", [])
    year_map: dict[str, str] = {}
    for t in tahun_list:
      if isinstance(t, dict):
        year_map[str(t.get("val", ""))] = str(t.get("label", ""))

    observations: dict[str, object] = data.get("datacontent", {})
    seen_years: set[str] = set()
    for key, value in observations.items():
      if not isinstance(key, str) or not isinstance(value, (int, float)):
        continue
      for year_id, year_label in year_map.items():
        if year_id in key:
          if year_label not in seen_years:
            obs_date: str = f"{year_label}-12-31"
            all_observations.append((obs_date, float(value)))
            seen_years.add(year_label)
          break

    time.sleep(BPS_REQUEST_DELAY)

  if not all_observations:
    return 0

  payload_bytes: bytes = str(all_observations).encode("utf-8")
  content_hash: str = sha256(payload_bytes).hexdigest()
  source_record_key: str = f"bps_data:{var_id}"

  existing_raw = supabase_client.find_raw_record_by_key(
    source_record_key=source_record_key,
  )

  if existing_raw is None:
    supabase_client.insert_raw_record_simple(
      raw_source_id=raw_source_id,
      record_type="bps_data",
      source_record_key=source_record_key,
      source_entity_key=var_id,
      payload_json={"observations": all_observations},
      payload_hash=content_hash,
      schema_version="1",
    )
  else:
    supabase_client.update_raw_record_payload(
      record_id=existing_raw[0],
      payload_json={"observations": all_observations},
      payload_hash=content_hash,
    )

  _upsert_bps_series_metadata(supabase_client, var_id, title, category, unit)

  inserted: int = 0
  for obs_date, obs_value in all_observations:
    result = supabase_client.upsert_macro_observation(
      series_id=series_id,
      observation_date=obs_date,
      value_numeric=obs_value,
    )
    if result.created:
      inserted += 1

  supabase_client.update_macro_series_fetched(series_id)

  return inserted


def _fetch_year_ids(
  *,
  http_client: HttpClient,
  bps_api_key: str,
  var_id: str,
) -> list[str]:
  data: dict[str, object] = _bps_api_request(
    http_client=http_client,
    bps_api_key=bps_api_key,
    endpoint="list",
    params={
      "model": "th",
      "domain": BPS_DOMAIN_NATIONAL,
      "var": var_id,
      "lang": "eng",
      "row": "100",
    },
  )

  if data.get("status") != "OK":
    return []

  periods: list[dict[str, object]] = []
  raw_data = data.get("data", [])
  if isinstance(raw_data, list) and len(raw_data) > 1:
    periods = raw_data[1]

  year_ids: list[str] = []
  for p in periods:
    if isinstance(p, dict):
      th_id = str(p.get("th_id", ""))
      if th_id:
        year_ids.append(th_id)

  return sorted(year_ids, reverse=True)


def _bps_api_request(
  *,
  http_client: HttpClient,
  bps_api_key: str,
  endpoint: str,
  params: dict[str, str],
) -> dict[str, object]:
  query: dict[str, str] = {**params, "key": bps_api_key}
  last_error: Exception | None = None

  for attempt in range(BPS_MAX_RETRIES):
    try:
      response = http_client.request(
        "GET",
        f"{BPS_API_BASE}/{endpoint}",
        query=query,
        headers=BPS_HEADERS,
        timeout_seconds=30,
      )
      if response.status_code == 403:
        if attempt < BPS_MAX_RETRIES - 1:
          time.sleep(BPS_RETRY_DELAY * (attempt + 1))
          continue
        raise ValueError(f"BPS API WAF blocked after {BPS_MAX_RETRIES} retries")

      if response.status_code != 200:
        raise ValueError(f"BPS API error: status={response.status_code}")

      data = response.json()
      if not isinstance(data, dict):
        raise ValueError("BPS API returned non-dict")

      return data

    except Exception as exc:
      last_error = exc
      if attempt < BPS_MAX_RETRIES - 1:
        time.sleep(BPS_RETRY_DELAY * (attempt + 1))

  raise last_error or ValueError("BPS API request failed")


def _upsert_bps_series_metadata(
  supabase_client: SupabaseRestClient,
  var_id: str,
  title: str,
  category: str,
  unit: str,
) -> None:
  series_id: str = f"bps_{var_id}"
  supabase_client.upsert_macro_series(
    series_id=series_id,
    title=title,
    category=category,
    frequency="yearly",
    units=unit,
  )
