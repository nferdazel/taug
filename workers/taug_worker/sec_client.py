from __future__ import annotations

import json

from .http_client import HttpClient


class SecClient:
  def __init__(self, *, http_client: HttpClient, user_agent: str) -> None:
    self._http_client = http_client
    self._user_agent = user_agent

  def fetch_submissions(self, cik: str) -> dict[str, object]:
    normalized_cik: str = cik.zfill(10)
    response = self._http_client.request(
      "GET",
      f"https://data.sec.gov/submissions/CIK{normalized_cik}.json",
      headers={
        "Accept": "application/json",
        "User-Agent": self._user_agent,
      },
      timeout_seconds=30,
    )
    if response.status_code != 200:
      body_text: str = response.body.decode("utf-8", errors="replace")
      raise ValueError(
        f"SEC submissions fetch failed for CIK {normalized_cik}: "
        f"status={response.status_code} body={body_text[:400]}"
      )

    payload: object = response.json()
    if not isinstance(payload, dict):
      raise ValueError(f"Unexpected SEC submissions payload for CIK {normalized_cik}")

    return payload

  @staticmethod
  def canonical_payload_bytes(payload: dict[str, object]) -> bytes:
    return json.dumps(
      payload,
      sort_keys=True,
      separators=(",", ":"),
      ensure_ascii=True,
    ).encode("utf-8")
