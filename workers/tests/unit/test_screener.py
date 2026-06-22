from __future__ import annotations

from taug_worker.jobs.execute_screener import (
  _build_query,
  _OPERATOR_MAP,
  _METRIC_COLUMNS,
)


class TestBuildQuery:
  def test_empty_filters(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["select"] == "*"
    assert query["limit"] == "100"
    assert "universe_code" not in query

  def test_single_filter_gt(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "gross_margin", "operator": "gt", "value": 0.4},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["gross_margin"] == "gt.0.4"

  def test_single_filter_lt(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "pe", "operator": "lt", "value": 15},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["pe"] == "lt.15"

  def test_multiple_filters(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "gross_margin", "operator": "gt", "value": 0.4},
        {"metric_code": "roe", "operator": "gt", "value": 0.1},
        {"metric_code": "debt_equity", "operator": "lt", "value": 1.0},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["gross_margin"] == "gt.0.4"
    assert query["roe"] == "gt.0.1"
    assert query["debt_equity"] == "lt.1.0"

  def test_sort_single(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[
        {"metric_code": "roe", "direction": "desc"},
      ],
      universe_code="all",
      limit=100,
    )
    assert query["order"] == "roe.desc"

  def test_sort_multiple(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[
        {"metric_code": "gross_margin", "direction": "desc"},
        {"metric_code": "roe", "direction": "asc"},
      ],
      universe_code="all",
      limit=100,
    )
    assert query["order"] == "gross_margin.desc,roe.asc"

  def test_universe_code(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[],
      universe_code="us_common_stocks",
      limit=100,
    )
    assert query["universe_code"] == "eq.us_common_stocks"

  def test_universe_all_not_added(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert "universe_code" not in query

  def test_limit_capped_at_500(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[],
      universe_code="all",
      limit=1000,
    )
    assert query["limit"] == "500"

  def test_is_null_operator(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "pe", "operator": "is_null"},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["pe"] == "is.null"

  def test_is_not_null_operator(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "pe", "operator": "is_not_null"},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert query["pe"] == "not.is.null"

  def test_invalid_metric_code_skipped(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "nonexistent", "operator": "gt", "value": 10},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert "nonexistent" not in query

  def test_invalid_operator_skipped(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "pe", "operator": "like", "value": 10},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert "pe" not in query

  def test_missing_metric_code_skipped(self) -> None:
    query = _build_query(
      filter_definition=[
        {"operator": "gt", "value": 10},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert len([k for k in query if k not in ("select", "limit")]) == 0

  def test_null_value_skipped(self) -> None:
    query = _build_query(
      filter_definition=[
        {"metric_code": "pe", "operator": "gt", "value": None},
      ],
      sort_definition=[],
      universe_code="all",
      limit=100,
    )
    assert "pe" not in query

  def test_sort_invalid_metric_skipped(self) -> None:
    query = _build_query(
      filter_definition=[],
      sort_definition=[
        {"metric_code": "nonexistent", "direction": "desc"},
      ],
      universe_code="all",
      limit=100,
    )
    assert "order" not in query

  def test_all_operators_covered(self) -> None:
    expected = {"eq", "neq", "gt", "gte", "lt", "lte"}
    assert set(_OPERATOR_MAP.keys()) == expected

  def test_metric_columns_not_empty(self) -> None:
    assert len(_METRIC_COLUMNS) >= 19
