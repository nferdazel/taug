from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import json
from typing import Any

from .http_client import HttpClient


@dataclass(frozen=True)
class RawSource:
  id: int
  code: str


class SupabaseRestClient:
  def __init__(
    self,
    *,
    http_client: HttpClient,
    supabase_url: str,
    service_role_key: str,
    schema: str = "taug",
  ) -> None:
    self._http_client = http_client
    self._base_url = supabase_url.rstrip("/")
    self._service_role_key = service_role_key
    self._schema = schema

  def ensure_sec_source(self) -> RawSource:
    payload: list[dict[str, object]] = [
      {
        "code": "sec_edgar",
        "name": "SEC EDGAR",
        "source_type": "filings",
        "region": "US",
        "is_official": True,
        "licensing_notes": "Official SEC EDGAR public filings and submissions APIs.",
        "access_method": "https_api",
        "default_latency_class": "official_delayed",
      },
    ]
    self._request(
      "POST",
      "raw_sources",
      query={
        "on_conflict": "code",
      },
      headers={
        "Prefer": "resolution=merge-duplicates,return=minimal",
      },
      payload=payload,
    )

    rows: list[dict[str, Any]] = self._request(
      "GET",
      "raw_sources",
      query={
        "select": "id,code",
        "code": "eq.sec_edgar",
        "limit": "1",
      },
    )
    if not rows:
      raise ValueError("Failed to ensure SEC raw source row")

    row: dict[str, Any] = rows[0]
    return RawSource(id=int(row["id"]), code=str(row["code"]))

  def insert_fetch_run(
    self,
    *,
    raw_source_id: int,
    job_type: str,
    job_scope: dict[str, object],
    worker_version: str,
  ) -> str:
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "raw_fetch_runs",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "raw_source_id": raw_source_id,
          "job_type": job_type,
          "job_scope": job_scope,
          "status": "running",
          "worker_version": worker_version,
        },
      ],
    )
    return str(rows[0]["id"])

  def update_fetch_run(
    self,
    *,
    fetch_run_id: str,
    status: str,
    error_code: str | None = None,
    error_message: str | None = None,
    metadata: dict[str, object] | None = None,
  ) -> None:
    payload: dict[str, object] = {
      "status": status,
      "finished_at": datetime.now(timezone.utc).isoformat(),
    }
    if error_code is not None:
      payload["error_code"] = error_code
    if error_message is not None:
      payload["error_message"] = error_message[:1000]
    if metadata is not None:
      payload["metadata"] = metadata

    self._request(
      "PATCH",
      "raw_fetch_runs",
      query={"id": f"eq.{fetch_run_id}"},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )

  def insert_raw_record(
    self,
    *,
    raw_source_id: int,
    fetch_run_id: str,
    record_type: str,
    source_record_key: str,
    source_entity_key: str,
    payload_json: dict[str, object],
    payload_hash: str,
    metadata: dict[str, object],
  ) -> None:
    self._request(
      "POST",
      "raw_records",
      query={
        "on_conflict": "raw_source_id,record_type,source_record_key,payload_hash",
      },
      headers={"Prefer": "resolution=ignore-duplicates,return=minimal"},
      payload=[
        {
          "raw_source_id": raw_source_id,
          "fetch_run_id": fetch_run_id,
          "record_type": record_type,
          "source_record_key": source_record_key,
          "source_entity_key": source_entity_key,
          "payload_json": payload_json,
          "payload_hash": payload_hash,
          "metadata": metadata,
        },
      ],
    )

  def insert_audit_event(
    self,
    *,
    event_type: str,
    entity_type: str,
    entity_id: str,
    severity: str,
    payload: dict[str, object],
    reference_type: str | None = None,
    reference_id: str | None = None,
  ) -> None:
    body: dict[str, object] = {
      "event_type": event_type,
      "entity_type": entity_type,
      "entity_id": entity_id,
      "severity": severity,
      "payload": payload,
    }
    if reference_type is not None:
      body["reference_type"] = reference_type
    if reference_id is not None:
      body["reference_id"] = reference_id

    self._request(
      "POST",
      "audit_events",
      headers={"Prefer": "return=minimal"},
      payload=[body],
    )

  def insert_validation_event(
    self,
    *,
    entity_type: str,
    entity_id: str,
    validation_rule: str,
    status: str,
    message: str,
    payload: dict[str, object],
  ) -> None:
    self._request(
      "POST",
      "validation_events",
      headers={"Prefer": "return=minimal"},
      payload=[
        {
          "entity_type": entity_type,
          "entity_id": entity_id,
          "validation_rule": validation_rule,
          "status": status,
          "message": message[:1000],
          "payload": payload,
        },
      ],
    )

  def _request(
    self,
    method: str,
    table: str,
    *,
    query: dict[str, str] | None = None,
    headers: dict[str, str] | None = None,
    payload: object | None = None,
  ) -> list[dict[str, Any]]:
    merged_headers: dict[str, str] = {
      "apikey": self._service_role_key,
      "Authorization": f"Bearer {self._service_role_key}",
      "Accept-Profile": self._schema,
      "Content-Profile": self._schema,
      "Content-Type": "application/json",
    }
    if headers:
      merged_headers.update(headers)

    body: bytes | None = None
    if payload is not None:
      body = json.dumps(payload, separators=(",", ":"), ensure_ascii=True).encode(
        "utf-8"
      )

    response = self._http_client.request(
      method,
      f"{self._base_url}/rest/v1/{table}",
      headers=merged_headers,
      query=query,
      body=body,
      timeout_seconds=30,
    )

    if response.status_code not in (200, 201, 204):
      body_text: str = response.body.decode("utf-8", errors="replace")
      raise ValueError(
        f"Supabase REST request failed: table={table} method={method} "
        f"status={response.status_code} body={body_text[:500]}"
      )

    if response.status_code == 204 or not response.body:
      return []

    data: object = response.json()
    if not isinstance(data, list):
      raise ValueError(f"Unexpected Supabase response shape for table {table}")
    return data
