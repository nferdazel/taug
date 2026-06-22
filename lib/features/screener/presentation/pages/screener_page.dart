import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/schema/app_schema.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_sanitizer.dart';

class ScreenerPage extends StatefulWidget {
  const ScreenerPage({super.key});

  @override
  State<ScreenerPage> createState() => _ScreenerPageState();
}

class _ScreenerPageState extends State<ScreenerPage> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'display_name';
  bool _sortAsc = true;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from(AppSchema.screenerResults)
          .select()
          .order('display_name');

      setState(() {
        _rows = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _recomputeFilteredRows();
      });
    } catch (e) {
      setState(() {
        _error = ErrorSanitizer.message(e);
        _isLoading = false;
      });
    }
  }

  void _recomputeFilteredRows() {
    var rows = _rows;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      rows = rows.where((r) {
        final name = (r['display_name'] as String? ?? '').toLowerCase();
        final ticker = (r['primary_ticker'] as String? ?? '').toLowerCase();
        return name.contains(q) || ticker.contains(q);
      }).toList();
    }

    rows.sort((a, b) {
      final aVal = a[_sortBy];
      final bVal = b[_sortBy];
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return 1;
      if (bVal == null) return -1;
      if (aVal is num && bVal is num) {
        return _sortAsc
            ? aVal.compareTo(bVal)
            : bVal.compareTo(aVal);
      }
      final cmp = aVal.toString().compareTo(bVal.toString());
      return _sortAsc ? cmp : -cmp;
    });

    _filteredRows = rows;
  }

  void _onSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = column;
        _sortAsc = false;
      }
      _recomputeFilteredRows();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: <Widget>[
          const Text('SCREENER', style: AppTypography.monoSection),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 200,
            height: 28,
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _searchDebounce?.cancel();
                _searchDebounce = Timer(
                  const Duration(milliseconds: 300),
                  () {
                    setState(() {
                      _recomputeFilteredRows();
                    });
                  },
                );
              },
              style: AppTypography.monoData.copyWith(fontSize: 11),
              decoration: const InputDecoration(
                hintText: 'Filter...',
                hintStyle: AppTypography.monoMeta,
                prefixIcon: Icon(Icons.search, size: 12),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppThemeColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppThemeColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppThemeColors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '${_filteredRows.length} companies',
            style: AppTypography.monoTiny.copyWith(
              color: AppThemeColors.textTertiary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 24,
            height: 28,
            child: IconButton(
              onPressed: _loadData,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: AppTypography.bodySmall),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1400,
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRows.length,
                itemExtent: 32,
                itemBuilder: (BuildContext context, int index) {
                  return _buildRow(_filteredRows[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppThemeColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: <Widget>[
          _buildHeaderCell('COMPANY', 160, 'display_name'),
          _buildHeaderCell('TICKER', 60, 'primary_ticker'),
          _buildHeaderCell('GM%', 65, 'gross_margin'),
          _buildHeaderCell('OM%', 65, 'operating_margin'),
          _buildHeaderCell('NM%', 60, 'net_margin'),
          _buildHeaderCell('ROE%', 60, 'roe'),
          _buildHeaderCell('ROA%', 60, 'roa'),
          _buildHeaderCell('D/E', 55, 'debt_equity'),
          _buildHeaderCell('CR', 55, 'current_ratio'),
          _buildHeaderCell('FCF', 80, 'fcf'),
          _buildHeaderCell('FCF%', 60, 'fcf_margin'),
          _buildHeaderCell('REV YOY%', 70, 'revenue_yoy'),
          _buildHeaderCell('FRESH', 60, 'statement_freshness'),
          _buildHeaderCell('COVERAGE', 70, 'filing_coverage_status'),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, String column) {
    final bool isActive = _sortBy == column;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _onSort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.monoSection.copyWith(
                fontSize: 10,
                color: isActive ? AppThemeColors.accent : null,
              ),
            ),
            if (isActive)
              Icon(
                _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: AppThemeColors.accent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row, int index) {
    final bool isEven = index.isEven;
    return RepaintBoundary(
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isEven ? null : AppThemeColors.backgroundLight.withAlpha(30),
          border: const Border(
            bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: <Widget>[
            _buildCell(
              row['display_name'] as String? ?? '',
              160,
              style: AppTypography.body.copyWith(fontSize: 11),
            ),
            _buildCell(
              row['primary_ticker'] as String? ?? '',
              60,
              style: AppTypography.monoData.copyWith(
                color: AppThemeColors.accent,
                fontSize: 11,
              ),
            ),
            _buildMetricCell(row['gross_margin'], 65),
            _buildMetricCell(row['operating_margin'], 65),
            _buildMetricCell(row['net_margin'], 60),
            _buildMetricCell(row['roe'], 60),
            _buildMetricCell(row['roa'], 60),
            _buildMetricCell(row['debt_equity'], 55),
            _buildMetricCell(row['current_ratio'], 55),
            _buildMoneyCell(row['fcf'], 80),
            _buildMetricCell(row['fcf_margin'], 60),
            _buildMetricCell(row['revenue_yoy'], 70),
            _buildFreshnessCell(row['statement_freshness'] as String?, 60),
            _buildCoverageCell(row['filing_coverage_status'] as String?, 70),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String value, double width, {TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: style ?? AppTypography.monoMeta,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMetricCell(dynamic value, double width) {
    if (value == null) {
      return SizedBox(
        width: width,
        child: Text(
          '--',
          textAlign: TextAlign.right,
          style: AppTypography.monoMeta.copyWith(
            color: AppThemeColors.textTertiary,
          ),
        ),
      );
    }
    final double v = (value as num).toDouble();
    final bool isNegative = v < 0;
    return SizedBox(
      width: width,
      child: Text(
        (v * 100).toStringAsFixed(1),
        textAlign: TextAlign.right,
        style: AppTypography.monoData.copyWith(
          color: isNegative ? AppThemeColors.bearish : AppThemeColors.textPrimary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMoneyCell(dynamic value, double width) {
    if (value == null) {
      return SizedBox(
        width: width,
        child: Text(
          '--',
          textAlign: TextAlign.right,
          style: AppTypography.monoMeta.copyWith(
            color: AppThemeColors.textTertiary,
          ),
        ),
      );
    }
    final double v = (value as num).toDouble();
    String formatted;
    if (v.abs() >= 1e9) {
      formatted = '${(v / 1e9).toStringAsFixed(1)}B';
    } else if (v.abs() >= 1e6) {
      formatted = '${(v / 1e6).toStringAsFixed(1)}M';
    } else {
      formatted = v.toStringAsFixed(0);
    }
    return SizedBox(
      width: width,
      child: Text(
        formatted,
        textAlign: TextAlign.right,
        style: AppTypography.monoData.copyWith(
          color: v < 0 ? AppThemeColors.bearish : AppThemeColors.textPrimary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildFreshnessCell(String? status, double width) {
    Color color;
    switch (status) {
      case 'fresh':
        color = AppThemeColors.bullish;
      case 'stale':
        color = AppThemeColors.warning;
      case 'outdated':
        color = AppThemeColors.bearish;
      default:
        color = AppThemeColors.textTertiary;
    }
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(80)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          (status ?? '--').toUpperCase(),
          style: AppTypography.monoTiny.copyWith(
            color: color,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCoverageCell(String? status, double width) {
    Color color;
    switch (status) {
      case 'good':
        color = AppThemeColors.bullish;
      case 'partial':
        color = AppThemeColors.warning;
      case 'minimal':
        color = AppThemeColors.bearish;
      default:
        color = AppThemeColors.textTertiary;
    }
    return SizedBox(
      width: width,
      child: Text(
        (status ?? '--').toUpperCase(),
        style: AppTypography.monoTiny.copyWith(
          color: color,
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
