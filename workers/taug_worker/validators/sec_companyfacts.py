from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ValidationFailure:
  code: str
  message: str
  details: dict[str, object]


def validate_sec_companyfacts_payload(
  payload: dict[str, object],
) -> tuple[ValidationFailure, ...]:
  failures: list[ValidationFailure] = []

  required_top_level_keys: tuple[str, ...] = ("cik", "entityName", "facts")
  missing_top_level_keys: list[str] = [
    key for key in required_top_level_keys if key not in payload
  ]
  if missing_top_level_keys:
    failures.append(
      ValidationFailure(
        code="missing_top_level_keys",
        message="SEC companyfacts payload is missing required top-level keys.",
        details={"missing_keys": missing_top_level_keys},
      )
    )

  cik_value: object = payload.get("cik")
  cik_is_valid: bool = False
  if isinstance(cik_value, str) and cik_value.strip():
    cik_is_valid = True
  elif isinstance(cik_value, int) and cik_value > 0:
    cik_is_valid = True
  if not cik_is_valid:
    failures.append(
      ValidationFailure(
        code="invalid_cik",
        message="SEC companyfacts payload contains an invalid cik value.",
        details={
          "value_type": type(cik_value).__name__,
          "value": cik_value,
        },
      )
    )

  entity_name_value: object = payload.get("entityName")
  if not isinstance(entity_name_value, str) or not entity_name_value.strip():
    failures.append(
      ValidationFailure(
        code="invalid_entity_name",
        message="SEC companyfacts payload contains an invalid entityName value.",
        details={"value_type": type(entity_name_value).__name__},
      )
    )

  facts_value: object = payload.get("facts")
  if not isinstance(facts_value, dict):
    failures.append(
      ValidationFailure(
        code="invalid_facts",
        message="SEC companyfacts payload contains a non-object facts field.",
        details={"value_type": type(facts_value).__name__},
      )
    )
    return tuple(failures)

  if not facts_value:
    failures.append(
      ValidationFailure(
        code="empty_facts",
        message="SEC companyfacts payload contains an empty facts object.",
        details={},
      )
    )
    return tuple(failures)

  non_object_taxonomies: list[str] = []
  taxonomies_with_facts: int = 0
  fact_count: int = 0
  invalid_units: list[dict[str, object]] = []
  for taxonomy_name, taxonomy_value in facts_value.items():
    if not isinstance(taxonomy_name, str):
      non_object_taxonomies.append(type(taxonomy_name).__name__)
      continue
    if not isinstance(taxonomy_value, dict):
      non_object_taxonomies.append(taxonomy_name)
      continue
    if taxonomy_value:
      taxonomies_with_facts += 1
    for fact_name, fact_value in taxonomy_value.items():
      if not isinstance(fact_name, str):
        invalid_units.append(
          {
            "taxonomy": taxonomy_name,
            "fact": type(fact_name).__name__,
            "reason": "invalid_fact_name",
          }
        )
        continue
      if not isinstance(fact_value, dict):
        invalid_units.append(
          {
            "taxonomy": taxonomy_name,
            "fact": fact_name,
            "reason": "invalid_fact_object",
            "value_type": type(fact_value).__name__,
          }
        )
        continue
      units_value: object = fact_value.get("units")
      if not isinstance(units_value, dict) or not units_value:
        invalid_units.append(
          {
            "taxonomy": taxonomy_name,
            "fact": fact_name,
            "reason": "missing_or_invalid_units",
            "value_type": type(units_value).__name__,
          }
        )
        continue
      fact_count += 1
      for unit_name, unit_entries in units_value.items():
        if not isinstance(unit_name, str) or not isinstance(unit_entries, list):
          invalid_units.append(
            {
              "taxonomy": taxonomy_name,
              "fact": fact_name,
              "unit": unit_name if isinstance(unit_name, str) else type(unit_name).__name__,
              "reason": "invalid_unit_entries",
              "value_type": type(unit_entries).__name__,
            }
          )

  if non_object_taxonomies:
    failures.append(
      ValidationFailure(
        code="invalid_taxonomy_objects",
        message="SEC companyfacts payload contains invalid taxonomy objects.",
        details={"taxonomies": non_object_taxonomies},
      )
    )

  if taxonomies_with_facts == 0 or fact_count == 0:
    failures.append(
      ValidationFailure(
        code="no_fact_payloads",
        message="SEC companyfacts payload did not expose any parseable fact payloads.",
        details={
          "taxonomies_with_facts": taxonomies_with_facts,
          "fact_count": fact_count,
        },
      )
    )

  if invalid_units:
    failures.append(
      ValidationFailure(
        code="invalid_fact_units",
        message="SEC companyfacts payload contains facts with invalid unit structures.",
        details={
          "count": len(invalid_units),
          "examples": invalid_units[:10],
        },
      )
    )

  return tuple(failures)
