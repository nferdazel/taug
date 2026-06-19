from __future__ import annotations

from workers.taug_worker.validators.sec_submissions import (
  ValidationFailure,
  validate_sec_submissions_payload,
)
from workers.taug_worker.validators.sec_companyfacts import (
  validate_sec_companyfacts_payload,
)
from workers.taug_worker.validators.raw_documents import (
  DocumentIntegrityFailure,
  validate_raw_document_integrity,
)

from hashlib import sha256


class TestSecSubmissionsValidator:
  def _valid_payload(self) -> dict[str, object]:
    return {
      "cik": "0000320193",
      "name": "Apple Inc.",
      "tickers": ["AAPL"],
      "filings": {
        "recent": {
          "accessionNumber": ["0000320193-24-000001"],
          "filingDate": ["2024-01-01"],
          "form": ["10-K"],
          "acceptanceDateTime": ["2024-01-01T10:00:00"],
          "primaryDocument": ["10-k.htm"],
        },
      },
    }

  def test_valid_payload_has_no_failures(self) -> None:
    failures = validate_sec_submissions_payload(self._valid_payload())
    assert len(failures) == 0

  def test_missing_top_level_keys(self) -> None:
    payload = {"cik": "0000320193"}
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "missing_top_level_keys" in codes

  def test_invalid_cik_empty(self) -> None:
    payload = self._valid_payload()
    payload["cik"] = ""
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_cik" in codes

  def test_invalid_cik_none(self) -> None:
    payload = self._valid_payload()
    payload["cik"] = None
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_cik" in codes

  def test_invalid_name(self) -> None:
    payload = self._valid_payload()
    payload["name"] = 123
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_name" in codes

  def test_invalid_tickers_not_list(self) -> None:
    payload = self._valid_payload()
    payload["tickers"] = "AAPL"
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_tickers" in codes

  def test_invalid_filings_not_dict(self) -> None:
    payload = self._valid_payload()
    payload["filings"] = "invalid"
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_filings" in codes

  def test_missing_recent_keys(self) -> None:
    payload = self._valid_payload()
    payload["filings"] = {"recent": {"accessionNumber": ["001"]}}
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "missing_recent_keys" in codes

  def test_recent_length_mismatch(self) -> None:
    payload = self._valid_payload()
    payload["filings"] = {
      "recent": {
        "accessionNumber": ["001", "002"],
        "filingDate": ["2024-01-01"],
        "form": ["10-K"],
        "acceptanceDateTime": ["2024-01-01T10:00:00"],
        "primaryDocument": ["10-k.htm"],
      },
    }
    failures = validate_sec_submissions_payload(payload)
    codes = [f.code for f in failures]
    assert "recent_length_mismatch" in codes

  def test_empty_payload_fails_multiple(self) -> None:
    failures = validate_sec_submissions_payload({})
    assert len(failures) >= 1


class TestSecCompanyfactsValidator:
  def _valid_payload(self) -> dict[str, object]:
    return {
      "cik": "0000320193",
      "entityName": "Apple Inc.",
      "facts": {
        "us-gaap": {
          "Revenues": {
            "label": "Revenues",
            "units": {
              "USD": [
                {"start": "2023-01-01", "end": "2023-12-31", "val": 383285000000},
              ],
            },
          },
        },
      },
    }

  def test_valid_payload_has_no_failures(self) -> None:
    failures = validate_sec_companyfacts_payload(self._valid_payload())
    assert len(failures) == 0

  def test_missing_top_level_keys(self) -> None:
    failures = validate_sec_companyfacts_payload({"cik": "0000320193"})
    codes = [f.code for f in failures]
    assert "missing_top_level_keys" in codes

  def test_invalid_cik_empty(self) -> None:
    payload = self._valid_payload()
    payload["cik"] = ""
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_cik" in codes

  def test_valid_cik_integer(self) -> None:
    payload = self._valid_payload()
    payload["cik"] = 320193
    failures = validate_sec_companyfacts_payload(payload)
    cik_failures = [f for f in failures if f.code == "invalid_cik"]
    assert len(cik_failures) == 0

  def test_invalid_entity_name(self) -> None:
    payload = self._valid_payload()
    payload["entityName"] = ""
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_entity_name" in codes

  def test_invalid_facts_not_dict(self) -> None:
    payload = self._valid_payload()
    payload["facts"] = "invalid"
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_facts" in codes

  def test_empty_facts(self) -> None:
    payload = self._valid_payload()
    payload["facts"] = {}
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "empty_facts" in codes

  def test_no_parseable_facts(self) -> None:
    payload = self._valid_payload()
    payload["facts"] = {"us-gaap": {}}
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "no_fact_payloads" in codes

  def test_invalid_fact_units(self) -> None:
    payload = self._valid_payload()
    payload["facts"] = {
      "us-gaap": {
        "Revenues": {
          "label": "Revenues",
          "units": "invalid",
        },
      },
    }
    failures = validate_sec_companyfacts_payload(payload)
    codes = [f.code for f in failures]
    assert "invalid_fact_units" in codes


class TestRawDocumentIntegrity:
  def test_valid_document_passes(self) -> None:
    body = b"test document content"
    content_hash = sha256(body).hexdigest()
    failures = validate_raw_document_integrity(
      body=body,
      content_hash=content_hash,
      byte_size=len(body),
    )
    assert len(failures) == 0

  def test_empty_body_fails(self) -> None:
    failures = validate_raw_document_integrity(
      body=b"",
      content_hash="a" * 64,
      byte_size=0,
    )
    codes = [f.code for f in failures]
    assert "empty_document_body" in codes
    assert "invalid_byte_size" in codes

  def test_hash_mismatch_fails(self) -> None:
    body = b"test content"
    failures = validate_raw_document_integrity(
      body=body,
      content_hash="a" * 64,
      byte_size=len(body),
    )
    codes = [f.code for f in failures]
    assert "content_hash_mismatch" in codes

  def test_invalid_hash_length_fails(self) -> None:
    body = b"test"
    failures = validate_raw_document_integrity(
      body=body,
      content_hash="short",
      byte_size=len(body),
    )
    codes = [f.code for f in failures]
    assert "invalid_content_hash_length" in codes

  def test_byte_size_mismatch_fails(self) -> None:
    body = b"test content"
    content_hash = sha256(body).hexdigest()
    failures = validate_raw_document_integrity(
      body=body,
      content_hash=content_hash,
      byte_size=999,
    )
    codes = [f.code for f in failures]
    assert "byte_size_mismatch" in codes
