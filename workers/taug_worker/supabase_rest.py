from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import json
from hashlib import sha256
from typing import Any

from .http_client import HttpClient


@dataclass(frozen=True)
class RawSource:
  id: int
  code: str


@dataclass(frozen=True)
class CanonicalSecurity:
  company_id: str
  security_id: str


@dataclass(frozen=True)
class PendingFilingDocument:
  filing_version_id: str
  filing_id: str
  raw_record_id: str
  accession_number: str
  cik: str
  primary_document: str
  filing_date: str


@dataclass(frozen=True)
class UpsertResult:
  id: str
  created: bool


@dataclass(frozen=True)
class IngestionCheckpoint:
  id: str
  raw_source_id: int
  job_type: str
  checkpoint_scope_key: str
  last_success_fetch_run_id: str | None
  checkpoint_data: dict[str, Any]
  updated_at: str


@dataclass(frozen=True)
class FilingRecord:
  id: str
  company_id: str
  filing_key: str


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

  def build_checkpoint_scope_key(
    self,
    *,
    job_type: str,
    scope: dict[str, object],
  ) -> str:
    canonical_scope: bytes = json.dumps(
      scope,
      ensure_ascii=True,
      separators=(",", ":"),
      sort_keys=True,
    ).encode("utf-8")
    scope_hash: str = sha256(canonical_scope).hexdigest()[:16]
    return f"{job_type}:{scope_hash}"

  def upsert_ingestion_checkpoint(
    self,
    *,
    raw_source_id: int,
    job_type: str,
    checkpoint_scope_key: str,
    last_success_fetch_run_id: str,
    checkpoint_data: dict[str, object],
  ) -> None:
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "ingestion_checkpoints",
      query={"on_conflict": "raw_source_id,job_type,checkpoint_scope_key"},
      headers={"Prefer": "resolution=merge-duplicates,return=representation"},
      payload=[
        {
          "raw_source_id": raw_source_id,
          "job_type": job_type,
          "checkpoint_scope_key": checkpoint_scope_key,
          "last_success_fetch_run_id": last_success_fetch_run_id,
          "checkpoint_data": checkpoint_data,
          "updated_at": datetime.now(timezone.utc).isoformat(),
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to upsert ingestion checkpoint")

  def get_ingestion_checkpoint(
    self,
    *,
    raw_source_id: int,
    job_type: str,
    checkpoint_scope_key: str,
  ) -> IngestionCheckpoint | None:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "ingestion_checkpoints",
      query={
        "select": (
          "id,raw_source_id,job_type,checkpoint_scope_key,"
          "last_success_fetch_run_id,checkpoint_data,updated_at"
        ),
        "raw_source_id": f"eq.{raw_source_id}",
        "job_type": f"eq.{job_type}",
        "checkpoint_scope_key": f"eq.{checkpoint_scope_key}",
        "limit": "1",
      },
    )
    if not rows:
      return None
    row: dict[str, Any] = rows[0]
    checkpoint_data: Any = row.get("checkpoint_data")
    return IngestionCheckpoint(
      id=str(row["id"]),
      raw_source_id=int(row["raw_source_id"]),
      job_type=str(row["job_type"]),
      checkpoint_scope_key=str(row["checkpoint_scope_key"]),
      last_success_fetch_run_id=(
        str(row["last_success_fetch_run_id"])
        if row.get("last_success_fetch_run_id") is not None
        else None
      ),
      checkpoint_data=checkpoint_data if isinstance(checkpoint_data, dict) else {},
      updated_at=str(row["updated_at"]),
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
  ) -> UpsertResult:
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "raw_records",
      query={
        "on_conflict": "raw_source_id,record_type,source_record_key,payload_hash",
      },
      headers={"Prefer": "resolution=ignore-duplicates,return=representation"},
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
    if rows:
      return UpsertResult(id=str(rows[0]["id"]), created=True)

    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "raw_records",
      query={
        "select": "id",
        "raw_source_id": f"eq.{raw_source_id}",
        "record_type": f"eq.{record_type}",
        "source_record_key": f"eq.{source_record_key}",
        "payload_hash": f"eq.{payload_hash}",
        "limit": "1",
      },
    )
    if not existing_rows:
      raise ValueError("Failed to resolve raw record after upsert")
    return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

  def ensure_canonical_security(
    self,
    *,
    cik: str,
    ticker: str | None,
    company_name: str,
  ) -> CanonicalSecurity:
    existing: CanonicalSecurity | None = self._get_security_by_identifier(
      identifier_type="CIK",
      identifier_value=cik,
    )
    if existing is not None:
      return existing

    company_rows: list[dict[str, Any]] = self._request(
      "POST",
      "companies",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "legal_name": company_name,
          "display_name": company_name,
          "domicile_country_code": "US",
          "metadata": {
            "cik": cik,
            "seed_source": "sec_edgar",
          },
        },
      ],
    )
    company_id: str = str(company_rows[0]["id"])

    security_name: str = company_name if ticker is None else f"{company_name} ({ticker})"
    security_rows: list[dict[str, Any]] = self._request(
      "POST",
      "securities",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "company_id": company_id,
          "ticker": ticker or cik,
          "name": security_name,
          "security_type": "common_stock",
          "is_primary_listing": True,
          "status": "active",
          "metadata": {
            "seed_source": "sec_edgar",
          },
        },
      ],
    )
    security_id: str = str(security_rows[0]["id"])

    self._request(
      "POST",
      "security_identifiers",
      query={"on_conflict": "identifier_type,identifier_value"},
      headers={"Prefer": "resolution=ignore-duplicates,return=minimal"},
      payload=[
        {
          "security_id": security_id,
          "identifier_type": "CIK",
          "identifier_value": cik,
          "source": "sec_edgar",
          "is_primary": True,
        },
      ],
    )
    if ticker is not None:
      self._request(
        "POST",
        "security_identifiers",
        query={"on_conflict": "identifier_type,identifier_value"},
        headers={"Prefer": "resolution=ignore-duplicates,return=minimal"},
        payload=[
          {
            "security_id": security_id,
            "identifier_type": "TICKER",
            "identifier_value": ticker,
            "source": "sec_edgar",
            "is_primary": True,
          },
        ],
      )

    return CanonicalSecurity(company_id=company_id, security_id=security_id)

  def upsert_filing(
    self,
    *,
    company_id: str,
    raw_source_id: int,
    filing_type: str,
    filing_key: str,
    filing_date: str,
    acceptance_datetime: str | None,
    report_date: str | None,
    is_amendment: bool,
    metadata: dict[str, object],
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "filings",
      query={
        "select": "id",
        "raw_source_id": f"eq.{raw_source_id}",
        "filing_key": f"eq.{filing_key}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "filings",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "company_id": company_id,
          "raw_source_id": raw_source_id,
          "filing_type": filing_type,
          "filing_key": filing_key,
          "filing_date": filing_date,
          "acceptance_datetime": acceptance_datetime,
          "report_date": report_date,
          "is_amendment": is_amendment,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to resolve filing after upsert")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def upsert_filing_version(
    self,
    *,
    filing_id: str,
    raw_record_id: str,
    parser_version: str,
    metadata: dict[str, object],
  ) -> UpsertResult:
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "filing_versions",
      query={"on_conflict": "filing_id,version_number"},
      headers={"Prefer": "resolution=ignore-duplicates,return=representation"},
      payload=[
        {
          "filing_id": filing_id,
          "version_number": 1,
          "raw_record_id": raw_record_id,
          "parser_version": parser_version,
          "status": "active",
          "metadata": metadata,
        },
      ],
    )
    if rows:
      return UpsertResult(id=str(rows[0]["id"]), created=True)

    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "filing_versions",
      query={
        "select": "id",
        "filing_id": f"eq.{filing_id}",
        "version_number": "eq.1",
        "limit": "1",
      },
    )
    if not existing_rows:
      raise ValueError("Failed to resolve filing version after upsert")
    return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

  def list_pending_sec_filing_documents(self, *, limit: int) -> list[PendingFilingDocument]:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filing_versions",
      query={
        "select": "id,filing_id,raw_record_id,filings!inner(filing_key,filing_date,metadata)",
        "raw_document_id": "is.null",
        "limit": str(limit),
        "order": "created_at.asc",
      },
    )
    documents: list[PendingFilingDocument] = []
    for row in rows:
      filings_value: Any = row.get("filings")
      if not isinstance(filings_value, dict):
        continue
      metadata: Any = filings_value.get("metadata")
      if not isinstance(metadata, dict):
        continue

      primary_document: Any = metadata.get("primary_document")
      cik: Any = metadata.get("cik")
      filing_key: Any = filings_value.get("filing_key")
      filing_date: Any = filings_value.get("filing_date")
      raw_record_id: Any = row.get("raw_record_id")
      if not all(
        isinstance(value, str) and value.strip()
        for value in (primary_document, cik, filing_key, filing_date, raw_record_id)
      ):
        continue

      documents.append(
        PendingFilingDocument(
          filing_version_id=str(row["id"]),
          filing_id=str(row["filing_id"]),
          raw_record_id=str(raw_record_id),
          accession_number=str(filing_key),
          cik=str(cik),
          primary_document=str(primary_document),
          filing_date=str(filing_date),
        )
      )
    return documents

  def upload_raw_document(
    self,
    *,
    bucket: str,
    path: str,
    content_type: str,
    body: bytes,
  ) -> None:
    response = self._http_client.request(
      "POST",
      f"{self._base_url}/storage/v1/object/{bucket}/{path}",
      headers={
        "apikey": self._service_role_key,
        "Authorization": f"Bearer {self._service_role_key}",
        "Content-Type": content_type,
        "x-upsert": "false",
      },
      body=body,
      timeout_seconds=60,
    )
    if response.status_code not in (200, 201):
      body_text: str = response.body.decode("utf-8", errors="replace")
      raise ValueError(
        f"Supabase Storage upload failed: bucket={bucket} path={path} "
        f"status={response.status_code} body={body_text[:500]}"
      )

  def insert_raw_document(
    self,
    *,
    raw_source_id: int,
    fetch_run_id: str,
    document_type: str,
    document_url: str,
    storage_path: str,
    mime_type: str,
    content_hash: str,
    byte_size: int,
    published_at: str | None,
    metadata: dict[str, object],
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "raw_documents",
      query={
        "select": "id",
        "raw_source_id": f"eq.{raw_source_id}",
        "content_hash": f"eq.{content_hash}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "raw_documents",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "raw_source_id": raw_source_id,
          "fetch_run_id": fetch_run_id,
          "document_type": document_type,
          "document_url": document_url,
          "storage_path": storage_path,
          "mime_type": mime_type,
          "content_hash": content_hash,
          "byte_size": byte_size,
          "published_at": published_at,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to insert raw document")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def get_filing_record(
    self,
    *,
    filing_id: str,
  ) -> FilingRecord:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filings",
      query={
        "select": "id,company_id,filing_key",
        "id": f"eq.{filing_id}",
        "limit": "1",
      },
    )
    if not rows:
      raise ValueError(f"Failed to resolve filing row: {filing_id}")
    row: dict[str, Any] = rows[0]
    return FilingRecord(
      id=str(row["id"]),
      company_id=str(row["company_id"]),
      filing_key=str(row["filing_key"]),
    )

  def mark_raw_document_verified(
    self,
    *,
    raw_document_id: str,
  ) -> None:
    self._request(
      "PATCH",
      "raw_documents",
      query={"id": f"eq.{raw_document_id}"},
      headers={"Prefer": "return=minimal"},
      payload={"verified_at": datetime.now(timezone.utc).isoformat()},
    )

  def insert_raw_document_link(
    self,
    *,
    raw_record_id: str,
    raw_document_id: str,
    link_type: str,
  ) -> None:
    self._request(
      "POST",
      "raw_document_links",
      query={"on_conflict": "raw_record_id,raw_document_id,link_type"},
      headers={"Prefer": "resolution=ignore-duplicates,return=minimal"},
      payload=[
        {
          "raw_record_id": raw_record_id,
          "raw_document_id": raw_document_id,
          "link_type": link_type,
        },
      ],
    )

  def update_filing_version_document(
    self,
    *,
    filing_version_id: str,
    raw_document_id: str,
  ) -> None:
    self._request(
      "PATCH",
      "filing_versions",
      query={"id": f"eq.{filing_version_id}"},
      headers={"Prefer": "return=minimal"},
      payload={
        "raw_document_id": raw_document_id,
      },
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

  def _get_security_by_identifier(
    self,
    *,
    identifier_type: str,
    identifier_value: str,
  ) -> CanonicalSecurity | None:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "security_identifiers",
      query={
        "select": "security_id,securities(company_id)",
        "identifier_type": f"eq.{identifier_type}",
        "identifier_value": f"eq.{identifier_value}",
        "limit": "1",
      },
    )
    if not rows:
      return None

    row: dict[str, Any] = rows[0]
    securities_value: Any = row.get("securities")
    if not isinstance(securities_value, dict):
      raise ValueError("Unexpected security embedding in identifier lookup")
    company_id: Any = securities_value.get("company_id")
    if not isinstance(company_id, str):
      raise ValueError("Missing company_id in security identifier lookup")

    return CanonicalSecurity(
      company_id=company_id,
      security_id=str(row["security_id"]),
    )
