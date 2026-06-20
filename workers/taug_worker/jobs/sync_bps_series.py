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
BPS_REQUEST_DELAY: float = 3.0
BPS_MAX_RETRIES: int = 3
BPS_RETRY_DELAY: float = 15.0
BPS_HEADERS: dict[str, str] = {
  "Accept": "application/json",
  "User-Agent": "TaugResearchPlatform/1.0",
}

# Curated BPS macro variables for national Indonesia data
# These are variable IDs from BPS dynamic tables (domain 0000 = national)
BPS_MACRO_VARIABLES: tuple[dict[str, str], ...] = (
  {"var_id": "52892", "title": "GDP at Current Market Prices (Billion IDR)", "category": "gdp", "unit": "Billion IDR"},
  {"var_id": "52893", "title": "GDP Growth Rate (Percent)", "category": "gdp", "unit": "Percent"},
  {"var_id": "52895", "title": "GDP Per Capita (Thousand IDR)", "category": "gdp", "unit": "Thousand IDR"},
  {"var_id": "52900", "title": "CPI Inflation (Index)", "category": "inflation", "unit": "Index"},
  {"var_id": "52901", "title": "CPI Inflation YoY (Percent)", "category": "inflation", "unit": "Percent"},
  {"var_id": "52897", "title": "Population (Thousand)", "category": "employment", "unit": "Thousand"},
  {"var_id": "52898", "title": "Labor Force (Thousand)", "category": "employment", "unit": "Thousand"},
  {"var_id": "52899", "title": "Open Unemployment Rate (Percent)", "category": "employment", "unit": "Percent"},
  {"var_id": "52902", "title": "Exports (Million USD)", "category": "trade", "unit": "Million USD"},
  {"var_id": "52903", "title": "Imports (Million USD)", "category": "trade", "unit": "Million USD"},
  {"var_id": "52904", "title": "Trade Balance (Million USD)", "category": "trade", "unit": "Million USD"},
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
  years: tuple[str, ...] | None = None,
) -> BpsSyncSummary:
  if not bps_api_key:
    raise ValueError("BPS_API_KEY is required")

  target_vars: tuple[dict[str, str], ...] = variable_ids or BPS_MACRO_VARIABLES
  target_years: tuple[str, ...] = years or _default_years()

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
        years=target_years,
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
  years: tuple[str, ...],
) -> int:
  year_param: str = ";".join(years)
  series_id: str = f"bps_{var_id}"

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
    raise ValueError(f"BPS API error for var {var_id}: {data.get('message', 'unknown')}")

  payload_bytes: bytes = str(data).encode("utf-8")
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

  _upsert_bps_series_metadata(supabase_client, var_id, title, category, unit)

  inserted: int = 0
  observations: dict[str, object] = data.get("datacontent", {})
  tahun_list: list[dict[str, object]] = data.get("tahun", [])
  year_map: dict[str, str] = {}
  for t in tahun_list:
    if isinstance(t, dict):
      year_map[str(t.get("val", ""))] = str(t.get("label", ""))

  for key, value in observations.items():
    if not isinstance(key, str) or not isinstance(value, (int, float)):
      continue
    parts: list[str] = key.split("|") if "|" in key else [key]
    tahun_val: str = parts[-1][:3] if len(parts) >= 1 else ""
    obs_year: str | None = year_map.get(tahun_val)
    if not obs_year:
      for y in years:
        if tahun_val in y or y in tahun_val:
          obs_year = y
          break
    if not obs_year:
      continue
    obs_date: str = f"{obs_year}-12-31"

    result = supabase_client.upsert_macro_observation(
      series_id=series_id,
      observation_date=obs_date,
      value_numeric=float(value),
    )
    if result.created:
      inserted += 1

  supabase_client.update_macro_series_fetched(series_id)

  return inserted


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


def _default_years() -> tuple[str, ...]:
  current_year: int = datetime.now(timezone.utc).year
  return tuple(str(y) for y in range(current_year - 10, current_year + 1))
