from __future__ import annotations

from dataclasses import dataclass
import json
from typing import Any
from urllib import error, parse, request


@dataclass(frozen=True)
class HttpResponse:
  status_code: int
  headers: dict[str, str]
  body: bytes

  def json(self) -> Any:
    return json.loads(self.body.decode("utf-8"))


class HttpClient:
  def request(
    self,
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    query: dict[str, str] | None = None,
    body: bytes | None = None,
    timeout_seconds: int = 30,
  ) -> HttpResponse:
    final_url: str = url
    if query:
      separator: str = "&" if "?" in url else "?"
      final_url = f"{url}{separator}{parse.urlencode(query)}"

    req = request.Request(
      final_url,
      data=body,
      headers=headers or {},
      method=method,
    )

    try:
      with request.urlopen(req, timeout=timeout_seconds) as response:
        payload: bytes = response.read()
        normalized_headers: dict[str, str] = {
          key.lower(): value for key, value in response.headers.items()
        }
        return HttpResponse(
          status_code=response.status,
          headers=normalized_headers,
          body=payload,
        )
    except error.HTTPError as exc:
      payload = exc.read()
      normalized_headers = {
        key.lower(): value for key, value in exc.headers.items()
      }
      return HttpResponse(
        status_code=exc.code,
        headers=normalized_headers,
        body=payload,
      )
