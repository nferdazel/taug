import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';

/// Foundation table widget for financial data.
/// Uses Flutter's DataTable for Phase 0.
/// Will be upgraded to Syncfusion DataGrid for screener/financials if needed.
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final bool sortable;
  final int? frozenColumns;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortable = false,
    this.frozenColumns,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        columns: columns.map((c) => DataColumn(
          label: SizedBox(
            width: c.width,
            child: Text(
              c.label,
              style: AppTypography.monoLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          numeric: c.numeric,
        )).toList(),
        rows: rows.map((r) => DataRow(
          cells: r.cells.map((c) => DataCell(
            c.widget ?? Text(
              c.displayValue,
              style: c.numeric ? AppTypography.monoData : AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          )).toList(),
        )).toList(),
      ),
    );
  }
}

class AppTableColumn {
  final String key;
  final String label;
  final bool numeric;
  final double? width;

  const AppTableColumn({
    required this.key,
    required this.label,
    this.numeric = false,
    this.width,
  });
}

class AppTableRow {
  final List<AppTableCell> cells;

  const AppTableRow({required this.cells});
}

class AppTableCell {
  final String? value;
  final Widget? widget;
  final bool numeric;

  const AppTableCell({this.value, this.widget, this.numeric = false});

  String get displayValue => value ?? '—';
}

/// Formatted financial value for table cells
class MetricValueText extends StatelessWidget {
  final double? value;
  final String format;
  final bool highlight;

  const MetricValueText({
    super.key,
    required this.value,
    this.format = 'number',
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text('—', style: AppTypography.monoData.copyWith(
        color: AppThemeColors.textTertiary,
      ));
    }

    String formatted;
    final Color color = AppThemeColors.textPrimary;

    switch (format) {
      case 'percentage':
        formatted = '${(value! * 100).toStringAsFixed(2)}%';
        break;
      case 'currency':
        formatted = '\$${_formatLargeNumber(value!)}';
        break;
      case 'ratio':
        formatted = value!.toStringAsFixed(2);
        break;
      default:
        formatted = _formatLargeNumber(value!);
    }

    return Text(
      formatted,
      style: AppTypography.monoData.copyWith(color: color),
      textAlign: TextAlign.right,
    );
  }

  String _formatLargeNumber(double n) {
    if (n.abs() >= 1e12) return '${(n / 1e12).toStringAsFixed(2)}T';
    if (n.abs() >= 1e9) return '${(n / 1e9).toStringAsFixed(2)}B';
    if (n.abs() >= 1e6) return '${(n / 1e6).toStringAsFixed(2)}M';
    if (n.abs() >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(2);
  }
}
