from __future__ import annotations

from dataclasses import dataclass
import os


def _require_env(name: str) -> str:
  value: str | None = os.getenv(name)
  if value is None or not value.strip():
    raise ValueError(f"Missing required environment variable: {name}")
  return value.strip()


def _optional_csv(name: str) -> tuple[str, ...]:
  value: str = os.getenv(name, "").strip()
  if not value:
    return ()
  return tuple(item.strip() for item in value.split(",") if item.strip())


@dataclass(frozen=True)
class WorkerConfig:
  supabase_url: str
  supabase_service_role_key: str
  sec_user_agent: str
  sec_target_ciks: tuple[str, ...]
  raw_documents_bucket: str
  twelve_data_api_key: str

  @classmethod
  def from_env(cls) -> "WorkerConfig":
    return cls(
      supabase_url=_require_env("SUPABASE_URL"),
      supabase_service_role_key=_require_env("SUPABASE_SERVICE_ROLE_KEY"),
      sec_user_agent=_require_env("SEC_USER_AGENT"),
      sec_target_ciks=_optional_csv("SEC_TARGET_CIKS"),
      raw_documents_bucket=os.getenv("RAW_DOCUMENTS_BUCKET", "raw-documents").strip()
      or "raw-documents",
      twelve_data_api_key=os.getenv("TWELVE_DATA_API_KEY", "").strip(),
    )
