from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256


@dataclass(frozen=True)
class DocumentIntegrityFailure:
  code: str
  message: str
  details: dict[str, object]


def validate_raw_document_integrity(
  *,
  body: bytes,
  content_hash: str,
  byte_size: int,
) -> tuple[DocumentIntegrityFailure, ...]:
  failures: list[DocumentIntegrityFailure] = []

  if not body:
    failures.append(
      DocumentIntegrityFailure(
        code="empty_document_body",
        message="Fetched raw document body is empty.",
        details={},
      )
    )

  if byte_size <= 0:
    failures.append(
      DocumentIntegrityFailure(
        code="invalid_byte_size",
        message="Fetched raw document byte_size must be greater than zero.",
        details={"byte_size": byte_size},
      )
    )

  if len(content_hash) != 64:
    failures.append(
      DocumentIntegrityFailure(
        code="invalid_content_hash_length",
        message="Fetched raw document content_hash must be a 64-character sha256 hex digest.",
        details={"content_hash_length": len(content_hash)},
      )
    )
  else:
    expected_hash: str = sha256(body).hexdigest()
    if expected_hash != content_hash:
      failures.append(
        DocumentIntegrityFailure(
          code="content_hash_mismatch",
          message="Fetched raw document content_hash does not match the body bytes.",
          details={
            "expected_content_hash": expected_hash,
            "actual_content_hash": content_hash,
          },
        )
      )

  if len(body) != byte_size:
    failures.append(
      DocumentIntegrityFailure(
        code="byte_size_mismatch",
        message="Fetched raw document byte_size does not match the body length.",
        details={
          "expected_byte_size": len(body),
          "actual_byte_size": byte_size,
        },
      )
    )

  return tuple(failures)
