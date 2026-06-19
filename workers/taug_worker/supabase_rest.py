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
  raw_source_id: int
  filing_type: str
  filing_date: str
  report_date: str | None
  acceptance_datetime: str | None
  is_amendment: bool


@dataclass(frozen=True)
class FilingVersionRecord:
  id: str
  filing_id: str
  raw_record_id: str | None
  version_number: int
  status: str
  supersedes_filing_version_id: str | None


@dataclass(frozen=True)
class RawRecord:
  id: str
  source_entity_key: str | None
  payload_json: dict[str, Any]
  metadata: dict[str, Any]
  created_at: str


@dataclass(frozen=True)
class FinancialStatementItemKey:
  financial_statement_id: str
  lineage_source_type: str
  lineage_source_id: str


@dataclass(frozen=True)
class ReportingPeriodRecord:
  id: str
  company_id: str
  period_type: str
  fiscal_year: int
  fiscal_quarter: int | None
  period_end: str


@dataclass(frozen=True)
class FinancialStatementRecord:
  id: str
  filing_version_id: str
  statement_type: str
  period_end: str
  statement_version: int
  is_restated: bool
  supersedes_statement_id: str | None
  superseded_by_statement_id: str | None
  status: str


@dataclass(frozen=True)
class MetricDefinitionRecord:
  id: str
  code: str
  name: str
  category: str
  formula_version: str
  unit_type: str
  aggregation_mode: str


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

  def list_latest_raw_records(
    self,
    *,
    record_type: str,
    source_entity_keys: list[str],
    limit: int,
  ) -> list[RawRecord]:
    if not source_entity_keys:
      return []
    entity_key_filter: str = ",".join(source_entity_keys)
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "raw_records",
      query={
        "select": "id,source_entity_key,payload_json,metadata,created_at",
        "record_type": f"eq.{record_type}",
        "source_entity_key": f"in.({entity_key_filter})",
        "order": "created_at.desc",
        "limit": str(limit),
      },
    )
    latest_by_entity: dict[str, RawRecord] = {}
    for row in rows:
      source_entity_key: Any = row.get("source_entity_key")
      payload_json: Any = row.get("payload_json")
      metadata: Any = row.get("metadata")
      created_at: Any = row.get("created_at")
      if (
        not isinstance(source_entity_key, str)
        or not isinstance(payload_json, dict)
        or not isinstance(metadata, dict)
        or not isinstance(created_at, str)
      ):
        continue
      if source_entity_key in latest_by_entity:
        continue
      latest_by_entity[source_entity_key] = RawRecord(
        id=str(row["id"]),
        source_entity_key=source_entity_key,
        payload_json=payload_json,
        metadata=metadata,
        created_at=created_at,
      )
    return [latest_by_entity[key] for key in source_entity_keys if key in latest_by_entity]

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

  def get_canonical_security_by_cik(self, *, cik: str) -> CanonicalSecurity | None:
    return self._get_security_by_identifier(
      identifier_type="CIK",
      identifier_value=cik,
    )

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

  def list_filings_for_company(
    self,
    *,
    company_id: str,
    raw_source_id: int,
    limit: int,
  ) -> list[FilingRecord]:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filings",
      query={
        "select": (
          "id,company_id,filing_key,raw_source_id,filing_type,"
          "filing_date,report_date,acceptance_datetime,is_amendment"
        ),
        "company_id": f"eq.{company_id}",
        "raw_source_id": f"eq.{raw_source_id}",
        "order": "filing_date.desc,created_at.desc",
        "limit": str(limit),
      },
    )
    return [
      FilingRecord(
        id=str(row["id"]),
        company_id=str(row["company_id"]),
        filing_key=str(row["filing_key"]),
        raw_source_id=int(row["raw_source_id"]),
        filing_type=str(row["filing_type"]),
        filing_date=str(row["filing_date"]),
        report_date=(
          str(row["report_date"]) if row.get("report_date") is not None else None
        ),
        acceptance_datetime=(
          str(row["acceptance_datetime"])
          if row.get("acceptance_datetime") is not None
          else None
        ),
        is_amendment=bool(row["is_amendment"]),
      )
      for row in rows
    ]

  def get_filing_version_record(
    self,
    *,
    filing_version_id: str,
  ) -> FilingVersionRecord:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filing_versions",
      query={
        "select": (
          "id,filing_id,raw_record_id,version_number,status,"
          "supersedes_filing_version_id"
        ),
        "id": f"eq.{filing_version_id}",
        "limit": "1",
      },
    )
    if not rows:
      raise ValueError(f"Failed to resolve filing version row: {filing_version_id}")
    row: dict[str, Any] = rows[0]
    return FilingVersionRecord(
      id=str(row["id"]),
      filing_id=str(row["filing_id"]),
      raw_record_id=(
        str(row["raw_record_id"]) if row.get("raw_record_id") is not None else None
      ),
      version_number=int(row["version_number"]),
      status=str(row["status"]),
      supersedes_filing_version_id=(
        str(row["supersedes_filing_version_id"])
        if row.get("supersedes_filing_version_id") is not None
        else None
      ),
    )

  def get_active_filing_version_by_filing(
    self,
    *,
    filing_id: str,
  ) -> FilingVersionRecord | None:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filing_versions",
      query={
        "select": (
          "id,filing_id,raw_record_id,version_number,status,"
          "supersedes_filing_version_id"
        ),
        "filing_id": f"eq.{filing_id}",
        "status": "eq.active",
        "order": "version_number.desc",
        "limit": "1",
      },
    )
    if not rows:
      return None
    row: dict[str, Any] = rows[0]
    return FilingVersionRecord(
      id=str(row["id"]),
      filing_id=str(row["filing_id"]),
      raw_record_id=(
        str(row["raw_record_id"]) if row.get("raw_record_id") is not None else None
      ),
      version_number=int(row["version_number"]),
      status=str(row["status"]),
      supersedes_filing_version_id=(
        str(row["supersedes_filing_version_id"])
        if row.get("supersedes_filing_version_id") is not None
        else None
      ),
    )

  def list_active_filing_versions_for_filings(
    self,
    *,
    filing_ids: list[str],
    limit: int,
  ) -> list[FilingVersionRecord]:
    if not filing_ids:
      return []
    filing_id_filter: str = ",".join(filing_ids)
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filing_versions",
      query={
        "select": (
          "id,filing_id,raw_record_id,version_number,status,"
          "supersedes_filing_version_id"
        ),
        "filing_id": f"in.({filing_id_filter})",
        "status": "eq.active",
        "order": "version_number.desc",
        "limit": str(limit),
      },
    )
    seen_filing_ids: set[str] = set()
    records: list[FilingVersionRecord] = []
    for row in rows:
      filing_id: str = str(row["filing_id"])
      if filing_id in seen_filing_ids:
        continue
      seen_filing_ids.add(filing_id)
      records.append(
        FilingVersionRecord(
          id=str(row["id"]),
          filing_id=filing_id,
          raw_record_id=(
            str(row["raw_record_id"]) if row.get("raw_record_id") is not None else None
          ),
          version_number=int(row["version_number"]),
          status=str(row["status"]),
          supersedes_filing_version_id=(
            str(row["supersedes_filing_version_id"])
            if row.get("supersedes_filing_version_id") is not None
            else None
          ),
        )
      )
    return records

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
        "select": (
          "id,company_id,filing_key,raw_source_id,filing_type,"
          "filing_date,report_date,acceptance_datetime,is_amendment"
        ),
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
      raw_source_id=int(row["raw_source_id"]),
      filing_type=str(row["filing_type"]),
      filing_date=str(row["filing_date"]),
      report_date=(
        str(row["report_date"]) if row.get("report_date") is not None else None
      ),
      acceptance_datetime=(
        str(row["acceptance_datetime"])
        if row.get("acceptance_datetime") is not None
        else None
      ),
      is_amendment=bool(row["is_amendment"]),
    )

  def list_filing_candidates(
    self,
    *,
    company_id: str,
    raw_source_id: int,
    filing_date_lte: str,
    exclude_filing_id: str,
    limit: int,
  ) -> list[FilingRecord]:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "filings",
      query={
        "select": (
          "id,company_id,filing_key,raw_source_id,filing_type,"
          "filing_date,report_date,acceptance_datetime,is_amendment"
        ),
        "company_id": f"eq.{company_id}",
        "raw_source_id": f"eq.{raw_source_id}",
        "filing_date": f"lte.{filing_date_lte}",
        "id": f"neq.{exclude_filing_id}",
        "order": "filing_date.desc,created_at.desc",
        "limit": str(limit),
      },
    )
    return [
      FilingRecord(
        id=str(row["id"]),
        company_id=str(row["company_id"]),
        filing_key=str(row["filing_key"]),
        raw_source_id=int(row["raw_source_id"]),
        filing_type=str(row["filing_type"]),
        filing_date=str(row["filing_date"]),
        report_date=(
          str(row["report_date"]) if row.get("report_date") is not None else None
        ),
        acceptance_datetime=(
          str(row["acceptance_datetime"])
          if row.get("acceptance_datetime") is not None
          else None
        ),
        is_amendment=bool(row["is_amendment"]),
      )
      for row in rows
    ]

  def list_currencies(self) -> dict[str, str]:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "currencies",
      query={"select": "id,code", "limit": "200"},
    )
    return {
      str(row["code"]): str(row["id"])
      for row in rows
      if isinstance(row.get("code"), str) and row.get("id") is not None
    }

  def upsert_reporting_period(
    self,
    *,
    company_id: str,
    period_type: str,
    fiscal_year: int,
    fiscal_quarter: int | None,
    period_start: str | None,
    period_end: str,
    label: str,
    last_reported_at: str | None,
    last_fetched_at: str | None,
    last_verified_at: str | None,
    metadata: dict[str, object],
  ) -> UpsertResult:
    query: dict[str, str] = {
      "select": "id",
      "company_id": f"eq.{company_id}",
      "period_type": f"eq.{period_type}",
      "fiscal_year": f"eq.{fiscal_year}",
      "period_end": f"eq.{period_end}",
      "limit": "1",
    }
    query["fiscal_quarter"] = (
      f"eq.{fiscal_quarter}" if fiscal_quarter is not None else "is.null"
    )
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "reporting_periods",
      query=query,
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "reporting_periods",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "company_id": company_id,
          "period_type": period_type,
          "fiscal_year": fiscal_year,
          "fiscal_quarter": fiscal_quarter,
          "period_start": period_start,
          "period_end": period_end,
          "label": label,
          "last_reported_at": last_reported_at,
          "last_fetched_at": last_fetched_at,
          "last_verified_at": last_verified_at,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to upsert reporting period")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def list_reporting_periods_for_company(
    self,
    *,
    company_id: str,
    limit: int,
  ) -> list[ReportingPeriodRecord]:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "reporting_periods",
      query={
        "select": "id,company_id,period_type,fiscal_year,fiscal_quarter,period_end",
        "company_id": f"eq.{company_id}",
        "limit": str(limit),
      },
    )
    return [
      ReportingPeriodRecord(
        id=str(row["id"]),
        company_id=str(row["company_id"]),
        period_type=str(row["period_type"]),
        fiscal_year=int(row["fiscal_year"]),
        fiscal_quarter=(
          int(row["fiscal_quarter"]) if row.get("fiscal_quarter") is not None else None
        ),
        period_end=str(row["period_end"]),
      )
      for row in rows
    ]

  def upsert_statement_taxonomy_item(
    self,
    *,
    code: str,
    name: str,
    statement_type: str,
    unit_type: str | None,
    sign_convention: str,
    taxonomy_source: str,
    is_core: bool,
    metadata: dict[str, object],
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "statement_taxonomy_items",
      query={
        "select": "id",
        "taxonomy_source": f"eq.{taxonomy_source}",
        "code": f"eq.{code}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "statement_taxonomy_items",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "code": code,
          "name": name,
          "statement_type": statement_type,
          "unit_type": unit_type,
          "sign_convention": sign_convention,
          "taxonomy_source": taxonomy_source,
          "is_core": is_core,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to upsert statement taxonomy item")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def upsert_financial_statement(
    self,
    *,
    company_id: str,
    security_id: str | None,
    filing_id: str,
    filing_version_id: str,
    reporting_period_id: str | None,
    statement_type: str,
    statement_version: int,
    currency_id: str | None,
    period_start: str | None,
    period_end: str,
    published_at: str | None,
    is_restated: bool,
    last_reported_at: str | None,
    last_fetched_at: str | None,
    last_verified_at: str | None,
    parser_version: str | None,
    status: str,
    metadata: dict[str, object],
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "financial_statements",
      query={
        "select": "id",
        "filing_version_id": f"eq.{filing_version_id}",
        "statement_type": f"eq.{statement_type}",
        "period_end": f"eq.{period_end}",
        "statement_version": f"eq.{statement_version}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "financial_statements",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "company_id": company_id,
          "security_id": security_id,
          "filing_id": filing_id,
          "filing_version_id": filing_version_id,
          "reporting_period_id": reporting_period_id,
          "statement_type": statement_type,
          "statement_version": statement_version,
          "currency_id": currency_id,
          "period_start": period_start,
          "period_end": period_end,
          "published_at": published_at,
          "is_restated": is_restated,
          "last_reported_at": last_reported_at,
          "last_fetched_at": last_fetched_at,
          "last_verified_at": last_verified_at,
          "parser_version": parser_version,
          "status": status,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to upsert financial statement")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def list_financial_statements_for_filing_versions(
    self,
    *,
    filing_version_ids: list[str],
    limit: int,
  ) -> list[FinancialStatementRecord]:
    if not filing_version_ids:
      return []
    filing_version_filter: str = ",".join(filing_version_ids)
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "financial_statements",
      query={
        "select": (
          "id,filing_version_id,statement_type,period_end,statement_version,"
          "is_restated,supersedes_statement_id,superseded_by_statement_id,status"
        ),
        "filing_version_id": f"in.({filing_version_filter})",
        "limit": str(limit),
      },
    )
    return [
      FinancialStatementRecord(
        id=str(row["id"]),
        filing_version_id=str(row["filing_version_id"]),
        statement_type=str(row["statement_type"]),
        period_end=str(row["period_end"]),
        statement_version=int(row["statement_version"]),
        is_restated=bool(row["is_restated"]),
        supersedes_statement_id=(
          str(row["supersedes_statement_id"])
          if row.get("supersedes_statement_id") is not None
          else None
        ),
        superseded_by_statement_id=(
          str(row["superseded_by_statement_id"])
          if row.get("superseded_by_statement_id") is not None
          else None
        ),
        status=str(row["status"]),
      )
      for row in rows
    ]

  def update_financial_statement_supersession(
    self,
    *,
    financial_statement_id: str,
    supersedes_statement_id: str | None = None,
    superseded_by_statement_id: str | None = None,
    is_restated: bool | None = None,
    status: str | None = None,
  ) -> None:
    payload: dict[str, object] = {}
    if supersedes_statement_id is not None:
      payload["supersedes_statement_id"] = supersedes_statement_id
    if superseded_by_statement_id is not None:
      payload["superseded_by_statement_id"] = superseded_by_statement_id
    if is_restated is not None:
      payload["is_restated"] = is_restated
    if status is not None:
      payload["status"] = status
    if not payload:
      return
    self._request(
      "PATCH",
      "financial_statements",
      query={"id": f"eq.{financial_statement_id}"},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )

  def upsert_financial_statement_item(
    self,
    *,
    financial_statement_id: str,
    taxonomy_item_id: str | None,
    lineage_source_type: str,
    lineage_source_id: str,
    value_numeric: int | float | None,
    value_text: str | None,
    unit: str | None,
    scale: int | None,
    decimals: int | None,
    fact_period_start: str | None,
    fact_period_end: str | None,
    fact_instant: str | None,
    is_reported: bool,
    is_calculated: bool,
    confidence_score: float | None,
    metadata: dict[str, object],
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "financial_statement_items",
      query={
        "select": "id",
        "financial_statement_id": f"eq.{financial_statement_id}",
        "lineage_source_type": f"eq.{lineage_source_type}",
        "lineage_source_id": f"eq.{lineage_source_id}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "financial_statement_items",
      headers={"Prefer": "return=representation"},
      payload=[
        {
          "financial_statement_id": financial_statement_id,
          "taxonomy_item_id": taxonomy_item_id,
          "lineage_source_type": lineage_source_type,
          "lineage_source_id": lineage_source_id,
          "value_numeric": value_numeric,
          "value_text": value_text,
          "unit": unit,
          "scale": scale,
          "decimals": decimals,
          "fact_period_start": fact_period_start,
          "fact_period_end": fact_period_end,
          "fact_instant": fact_instant,
          "is_reported": is_reported,
          "is_calculated": is_calculated,
          "confidence_score": confidence_score,
          "metadata": metadata,
        },
      ],
    )
    if not rows:
      raise ValueError("Failed to upsert financial statement item")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

  def list_financial_statement_item_keys(
    self,
    *,
    financial_statement_ids: list[str],
    limit: int,
  ) -> set[FinancialStatementItemKey]:
    if not financial_statement_ids:
      return set()
    statement_id_filter: str = ",".join(financial_statement_ids)
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "financial_statement_items",
      query={
        "select": (
          "financial_statement_id,lineage_source_type,lineage_source_id"
        ),
        "financial_statement_id": f"in.({statement_id_filter})",
        "limit": str(limit),
      },
    )
    keys: set[FinancialStatementItemKey] = set()
    for row in rows:
      statement_id: Any = row.get("financial_statement_id")
      lineage_source_type: Any = row.get("lineage_source_type")
      lineage_source_id: Any = row.get("lineage_source_id")
      if (
        not isinstance(statement_id, str)
        or not isinstance(lineage_source_type, str)
        or not isinstance(lineage_source_id, str)
      ):
        continue
      keys.add(
        FinancialStatementItemKey(
          financial_statement_id=statement_id,
          lineage_source_type=lineage_source_type,
          lineage_source_id=lineage_source_id,
        )
      )
    return keys

  def bulk_insert_financial_statement_items(
    self,
    *,
    rows: list[dict[str, object]],
  ) -> None:
    if not rows:
      return
    self._request(
      "POST",
      "financial_statement_items",
      query={
        "on_conflict": (
          "financial_statement_id,lineage_source_type,lineage_source_id"
        ),
      },
      headers={"Prefer": "resolution=ignore-duplicates,return=minimal"},
      payload=rows,
    )

  def update_filing_version_supersession(
    self,
    *,
    filing_version_id: str,
    supersedes_filing_version_id: str | None = None,
    superseded_by_filing_version_id: str | None = None,
    status: str | None = None,
    is_restated: bool | None = None,
  ) -> None:
    payload: dict[str, object] = {}
    if supersedes_filing_version_id is not None:
      payload["supersedes_filing_version_id"] = supersedes_filing_version_id
    if superseded_by_filing_version_id is not None:
      payload["superseded_by_filing_version_id"] = superseded_by_filing_version_id
    if status is not None:
      payload["status"] = status
    if is_restated is not None:
      payload["is_restated"] = is_restated
    if not payload:
      return
    self._request(
      "PATCH",
      "filing_versions",
      query={"id": f"eq.{filing_version_id}"},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )

  def insert_restatement_event(
    self,
    *,
    entity_type: str,
    entity_id: str,
    prior_reference_id: str | None,
    new_reference_id: str | None,
    detection_method: str,
    status: str,
    payload: dict[str, object],
  ) -> None:
    self._request(
      "POST",
      "restatement_events",
      headers={"Prefer": "return=minimal"},
      payload=[
        {
          "entity_type": entity_type,
          "entity_id": entity_id,
          "prior_reference_id": prior_reference_id,
          "new_reference_id": new_reference_id,
          "detection_method": detection_method,
          "status": status,
          "payload": payload,
        },
      ],
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

  def list_securities_with_tickers(
    self,
    *,
    limit: int,
  ) -> list[tuple[str, str]]:
    query: dict[str, str] = {
      "select": "id,ticker",
      "status": "eq.active",
      "ticker": "not.is.null",
      "limit": "1000" if limit <= 0 else str(limit),
    }
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "securities",
      query=query,
    )
    results: list[tuple[str, str]] = []
    for row in rows:
      sec_id = row.get("id")
      ticker = row.get("ticker")
      if isinstance(sec_id, str) and isinstance(ticker, str) and ticker.strip():
        results.append((sec_id, ticker.strip()))
    return results

  def upsert_price_snapshot(
    self,
    *,
    security_id: str,
    ticker: str,
    close_price: float | None,
    market_cap: float | None,
    enterprise_value: float | None,
    shares_outstanding: float | None,
    price_date: str,
  ) -> UpsertResult:
    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "security_price_snapshots",
      query={
        "select": "id",
        "security_id": f"eq.{security_id}",
        "price_date": f"eq.{price_date}",
        "limit": "1",
      },
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    snap_payload: dict[str, object] = {
      "security_id": security_id,
      "price_date": price_date,
      "close_price": close_price,
      "market_cap": market_cap,
      "enterprise_value": enterprise_value,
      "shares_outstanding": shares_outstanding,
      "last_fetched_at": datetime.now(timezone.utc).isoformat(),
    }
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "security_price_snapshots",
      headers={"Prefer": "return=representation"},
      payload=[snap_payload],
    )
    if not rows:
      raise ValueError("Failed to upsert price snapshot")
    return UpsertResult(id=str(rows[0]["id"]), created=True)

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

  def get_primary_security_for_company(
    self,
    *,
    company_id: str,
  ) -> CanonicalSecurity | None:
    rows: list[dict[str, Any]] = self._request(
      "GET",
      "securities",
      query={
        "select": "id,company_id",
        "company_id": f"eq.{company_id}",
        "order": "is_primary_listing.desc,created_at.desc",
        "limit": "1",
      },
    )
    if not rows:
      return None
    return CanonicalSecurity(
      company_id=str(rows[0]["company_id"]),
      security_id=str(rows[0]["id"]),
    )

  def list_statement_history_for_company(
    self,
    *,
    company_id: str,
    limit: int,
  ) -> list[dict[str, Any]]:
    return self._request(
      "GET",
      "company_statement_history_v",
      query={
        "company_id": f"eq.{company_id}",
        "order": "period_end.desc,published_at.desc",
        "limit": str(limit),
      },
    )

  def list_metric_definitions(self) -> list[dict[str, Any]]:
    return self._request(
      "GET",
      "metric_definitions",
      query={
        "select": "id,code,name,category,formula_version,unit_type,aggregation_mode",
        "is_active": "eq.true",
        "order": "code",
        "limit": "100",
      },
    )

  def insert_metric_calculation_run(
    self,
    *,
    run_type: str,
    trigger_reason: str,
    worker_version: str,
    trigger_reference_type: str | None = None,
    trigger_reference_id: str | None = None,
    metadata: dict[str, object] | None = None,
  ) -> str:
    payload: dict[str, object] = {
      "run_type": run_type,
      "trigger_reason": trigger_reason,
      "worker_version": worker_version,
      "status": "running",
    }
    if trigger_reference_type is not None:
      payload["trigger_reference_type"] = trigger_reference_type
    if trigger_reference_id is not None:
      payload["trigger_reference_id"] = trigger_reference_id
    if metadata is not None:
      payload["metadata"] = metadata
    rows: list[dict[str, Any]] = self._request(
      "POST",
      "metric_calculation_runs",
      headers={"Prefer": "return=representation"},
      payload=[payload],
    )
    return str(rows[0]["id"])

  def update_metric_calculation_run(
    self,
    *,
    run_id: str,
    status: str,
    metadata: dict[str, object] | None = None,
  ) -> None:
    payload: dict[str, object] = {
      "status": status,
      "finished_at": datetime.now(timezone.utc).isoformat(),
    }
    if metadata is not None:
      payload["metadata"] = metadata
    self._request(
      "PATCH",
      "metric_calculation_runs",
      query={"id": f"eq.{run_id}"},
      headers={"Prefer": "return=minimal"},
      payload=payload,
    )

  def upsert_security_metric_snapshot(
    self,
    *,
    security_id: str,
    company_id: str,
    metric_definition_id: str,
    reporting_period_id: str | None,
    as_of_date: str,
    value_numeric: float | None,
    computation_status: str,
    stale_input_flag: bool,
    missing_input_flag: bool,
    validation_warning_flag: bool,
    currency_id: str | None,
    calculation_run_id: str,
    formula_version: str,
    input_fingerprint: str | None,
    metadata: dict[str, object] | None = None,
  ) -> UpsertResult:
    query: dict[str, str] = {
      "select": "id",
      "security_id": f"eq.{security_id}",
      "metric_definition_id": f"eq.{metric_definition_id}",
      "as_of_date": f"eq.{as_of_date}",
      "formula_version": f"eq.{formula_version}",
      "limit": "1",
    }
    if reporting_period_id is not None:
      query["reporting_period_id"] = f"eq.{reporting_period_id}"
    else:
      query["reporting_period_id"] = "is.null"

    existing_rows: list[dict[str, Any]] = self._request(
      "GET",
      "security_metric_snapshots",
      query=query,
    )
    if existing_rows:
      return UpsertResult(id=str(existing_rows[0]["id"]), created=False)

    snap_payload: dict[str, object] = {
      "security_id": security_id,
      "company_id": company_id,
      "metric_definition_id": metric_definition_id,
      "reporting_period_id": reporting_period_id,
      "as_of_date": as_of_date,
      "value_numeric": value_numeric,
      "computation_status": computation_status,
      "stale_input_flag": stale_input_flag,
      "missing_input_flag": missing_input_flag,
      "validation_warning_flag": validation_warning_flag,
      "currency_id": currency_id,
      "calculation_run_id": calculation_run_id,
      "formula_version": formula_version,
      "input_fingerprint": input_fingerprint,
    }
    if metadata is not None:
      snap_payload["metadata"] = metadata

    rows: list[dict[str, Any]] = self._request(
      "POST",
      "security_metric_snapshots",
      headers={"Prefer": "return=representation"},
      payload=[snap_payload],
    )
    if not rows:
      raise ValueError("Failed to upsert security metric snapshot")
    return UpsertResult(id=str(rows[0]["id"]), created=True)
