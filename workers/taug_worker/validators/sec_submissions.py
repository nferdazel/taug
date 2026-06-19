from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ValidationFailure:
  code: str
  message: str
  details: dict[str, object]


def validate_sec_submissions_payload(
  payload: dict[str, object],
) -> tuple[ValidationFailure, ...]:
  failures: list[ValidationFailure] = []

  top_level_required_keys: tuple[str, ...] = ("cik", "name", "tickers", "filings")
  missing_top_level_keys: list[str] = [
    key for key in top_level_required_keys if key not in payload
  ]
  if missing_top_level_keys:
    failures.append(
      ValidationFailure(
        code="missing_top_level_keys",
        message="SEC submissions payload is missing required top-level keys.",
        details={"missing_keys": missing_top_level_keys},
      )
    )

  cik_value: object = payload.get("cik")
  if not isinstance(cik_value, str) or not cik_value.strip():
    failures.append(
      ValidationFailure(
        code="invalid_cik",
        message="SEC submissions payload contains an invalid cik value.",
        details={"value_type": type(cik_value).__name__},
      )
    )

  name_value: object = payload.get("name")
  if not isinstance(name_value, str) or not name_value.strip():
    failures.append(
      ValidationFailure(
        code="invalid_name",
        message="SEC submissions payload contains an invalid company name.",
        details={"value_type": type(name_value).__name__},
      )
    )

  tickers_value: object = payload.get("tickers")
  if not isinstance(tickers_value, list):
    failures.append(
      ValidationFailure(
        code="invalid_tickers",
        message="SEC submissions payload contains a non-list tickers field.",
        details={"value_type": type(tickers_value).__name__},
      )
    )

  filings_value: object = payload.get("filings")
  if not isinstance(filings_value, dict):
    failures.append(
      ValidationFailure(
        code="invalid_filings",
        message="SEC submissions payload contains a non-object filings field.",
        details={"value_type": type(filings_value).__name__},
      )
    )
    return tuple(failures)

  recent_value: object = filings_value.get("recent")
  if not isinstance(recent_value, dict):
    failures.append(
      ValidationFailure(
        code="invalid_filings_recent",
        message="SEC submissions payload contains a non-object filings.recent field.",
        details={"value_type": type(recent_value).__name__},
      )
    )
    return tuple(failures)

  required_recent_keys: tuple[str, ...] = (
    "accessionNumber",
    "filingDate",
    "form",
    "acceptanceDateTime",
    "primaryDocument",
  )
  missing_recent_keys: list[str] = [
    key for key in required_recent_keys if key not in recent_value
  ]
  if missing_recent_keys:
    failures.append(
      ValidationFailure(
        code="missing_recent_keys",
        message="SEC submissions payload is missing required filings.recent keys.",
        details={"missing_keys": missing_recent_keys},
      )
    )
    return tuple(failures)

  recent_lengths: dict[str, int] = {}
  invalid_recent_types: list[str] = []
  for key in required_recent_keys:
    field_value: object = recent_value.get(key)
    if not isinstance(field_value, list):
      invalid_recent_types.append(key)
      continue
    recent_lengths[key] = len(field_value)

  if invalid_recent_types:
    failures.append(
      ValidationFailure(
        code="invalid_recent_field_types",
        message="SEC submissions payload contains non-list filings.recent fields.",
        details={"invalid_keys": invalid_recent_types},
      )
    )
    return tuple(failures)

  distinct_lengths: list[int] = sorted(set(recent_lengths.values()))
  if len(distinct_lengths) > 1:
    failures.append(
      ValidationFailure(
        code="recent_length_mismatch",
        message="SEC submissions payload contains mismatched filings.recent array lengths.",
        details={"field_lengths": recent_lengths},
      )
    )

  return tuple(failures)
