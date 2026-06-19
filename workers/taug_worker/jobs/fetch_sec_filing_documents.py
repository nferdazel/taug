from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from hashlib import sha256
import mimetypes
from pathlib import PurePosixPath

from ..__init__ import __version__
from ..sec_client import SecClient
from ..supabase_rest import SupabaseRestClient


@dataclass(frozen=True)
class DocumentFetchSummary:
  fetch_run_id: str
  attempted_documents: int
  stored_documents: int
  failed_documents: int
  stored_filing_version_ids: tuple[str, ...]
  failed_filing_version_ids: tuple[str, ...]


def run_fetch_sec_filing_documents(
  *,
  sec_client: SecClient,
  supabase_client: SupabaseRestClient,
  bucket: str,
  limit: int,
) -> DocumentFetchSummary:
  source = supabase_client.ensure_sec_source()
  pending_documents = supabase_client.list_pending_sec_filing_documents(limit=limit)
  checkpoint_scope: dict[str, object] = {
    "job_type": "document_fetch",
    "bucket": bucket,
  }
  checkpoint_scope_key: str = supabase_client.build_checkpoint_scope_key(
    job_type="document_fetch",
    scope=checkpoint_scope,
  )
  fetch_run_id = supabase_client.insert_fetch_run(
    raw_source_id=source.id,
    job_type="document_fetch",
    job_scope={
      "source": source.code,
      "limit": limit,
      "pending_documents": len(pending_documents),
      "checkpoint_scope_key": checkpoint_scope_key,
    },
    worker_version=__version__,
  )

  stored_count = 0
  failed_count = 0
  stored_filing_version_ids: list[str] = []
  failed_filing_version_ids: list[str] = []

  try:
    for pending in pending_documents:
      try:
        body = sec_client.fetch_filing_document(
          cik=pending.cik,
          accession_number=pending.accession_number,
          document_name=pending.primary_document,
        )
        content_hash = sha256(body).hexdigest()
        suffix = PurePosixPath(pending.primary_document).suffix or ".txt"
        storage_path = (
          f"raw/sec_edgar/{pending.filing_date[:4]}/{pending.filing_date[5:7]}/"
          f"{pending.filing_date[8:10]}/{pending.filing_version_id}{suffix}"
        )
        mime_type, _ = mimetypes.guess_type(pending.primary_document)
        final_mime_type = mime_type or "application/octet-stream"
        supabase_client.upload_raw_document(
          bucket=bucket,
          path=storage_path,
          content_type=final_mime_type,
          body=body,
        )
        document_url = (
          "https://www.sec.gov/Archives/edgar/data/"
          f"{int(pending.cik)}/{pending.accession_number.replace('-', '')}/"
          f"{pending.primary_document}"
        )
        raw_document_id = supabase_client.insert_raw_document(
          raw_source_id=source.id,
          fetch_run_id=fetch_run_id,
          document_type="sec_primary_filing_document",
          document_url=document_url,
          storage_path=storage_path,
          mime_type=final_mime_type,
          content_hash=content_hash,
          byte_size=len(body),
          published_at=f"{pending.filing_date}T00:00:00+00:00",
          metadata={
            "source": source.code,
            "filing_id": pending.filing_id,
            "filing_version_id": pending.filing_version_id,
            "cik": pending.cik,
            "accession_number": pending.accession_number,
            "primary_document": pending.primary_document,
          },
        )
        supabase_client.insert_raw_document_link(
          raw_record_id=pending.raw_record_id,
          raw_document_id=raw_document_id,
          link_type="primary_filing_document",
        )
        supabase_client.update_filing_version_document(
          filing_version_id=pending.filing_version_id,
          raw_document_id=raw_document_id,
        )
        supabase_client.insert_audit_event(
          event_type="raw_document_ingested",
          entity_type="filing_version",
          entity_id=pending.filing_version_id,
          severity="info",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "storage_path": storage_path,
            "document_url": document_url,
            "content_hash": content_hash,
            "byte_size": len(body),
          },
        )
        stored_filing_version_ids.append(pending.filing_version_id)
        stored_count += 1
      except Exception as exc:
        failed_count += 1
        failed_filing_version_ids.append(pending.filing_version_id)
        supabase_client.insert_validation_event(
          entity_type="filing_version",
          entity_id=pending.filing_version_id,
          validation_rule="sec_primary_document_fetch",
          status="failed",
          message=str(exc),
          payload={
            "source": source.code,
            "accession_number": pending.accession_number,
            "primary_document": pending.primary_document,
            "worker_version": __version__,
          },
        )
        supabase_client.insert_audit_event(
          event_type="raw_document_ingestion_failed",
          entity_type="filing_version",
          entity_id=pending.filing_version_id,
          severity="error",
          reference_type="raw_fetch_run",
          reference_id=fetch_run_id,
          payload={
            "source": source.code,
            "message": str(exc),
            "accession_number": pending.accession_number,
            "primary_document": pending.primary_document,
          },
        )

    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="success" if failed_count == 0 else "partial",
      metadata={
        "attempted_documents": len(pending_documents),
        "stored_documents": stored_count,
        "failed_documents": failed_count,
        "stored_filing_version_ids": stored_filing_version_ids,
        "failed_filing_version_ids": failed_filing_version_ids,
      },
    )
    if failed_count == 0:
      supabase_client.upsert_ingestion_checkpoint(
        raw_source_id=source.id,
        job_type="document_fetch",
        checkpoint_scope_key=checkpoint_scope_key,
        last_success_fetch_run_id=fetch_run_id,
        checkpoint_data={
          "source": source.code,
          "scope": checkpoint_scope,
          "attempted_documents": len(pending_documents),
          "stored_documents": stored_count,
          "failed_documents": failed_count,
          "stored_filing_version_ids": stored_filing_version_ids,
          "failed_filing_version_ids": failed_filing_version_ids,
          "checkpointed_at": datetime.now(timezone.utc).isoformat(),
        },
      )
    supabase_client.insert_audit_event(
      event_type="raw_fetch_run_completed" if failed_count == 0 else "raw_fetch_run_partial",
      entity_type="raw_fetch_run",
      entity_id=fetch_run_id,
      severity="info" if failed_count == 0 else "warning",
      payload={
        "source": source.code,
        "attempted_documents": len(pending_documents),
        "stored_documents": stored_count,
        "failed_documents": failed_count,
        "stored_filing_version_ids": stored_filing_version_ids,
        "failed_filing_version_ids": failed_filing_version_ids,
      },
    )
  except Exception as exc:
    supabase_client.update_fetch_run(
      fetch_run_id=fetch_run_id,
      status="failed",
      error_code="worker_crash",
      error_message=str(exc),
      metadata={
        "attempted_documents": len(pending_documents),
        "stored_documents": stored_count,
        "failed_documents": failed_count,
        "stored_filing_version_ids": stored_filing_version_ids,
        "failed_filing_version_ids": failed_filing_version_ids,
      },
    )
    supabase_client.insert_audit_event(
      event_type="raw_fetch_run_failed",
      entity_type="raw_fetch_run",
      entity_id=fetch_run_id,
      severity="error",
      payload={
        "source": source.code,
        "message": str(exc),
        "attempted_documents": len(pending_documents),
        "stored_documents": stored_count,
        "failed_documents": failed_count,
        "stored_filing_version_ids": stored_filing_version_ids,
        "failed_filing_version_ids": failed_filing_version_ids,
      },
    )
    raise

  return DocumentFetchSummary(
    fetch_run_id=fetch_run_id,
    attempted_documents=len(pending_documents),
    stored_documents=stored_count,
    failed_documents=failed_count,
    stored_filing_version_ids=tuple(stored_filing_version_ids),
    failed_filing_version_ids=tuple(failed_filing_version_ids),
  )
