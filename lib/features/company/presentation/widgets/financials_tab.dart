import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';

class FinancialsTab extends StatelessWidget {
  final WorkspaceProvider provider;

  const FinancialsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final statements = provider.statements;

      if (statements.isEmpty) {
        return const Center(
          child: Text('No financial data available', style: TextStyle(color: Colors.grey)),
        );
      }

      final incomeStatements = statements
          .where((s) => s.statementType == 'income_statement')
          .toList();
      final balanceSheets = statements
          .where((s) => s.statementType == 'balance_sheet')
          .toList();
      final cashFlows = statements
          .where((s) => s.statementType == 'cash_flow')
          .toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (incomeStatements.isNotEmpty) ...[
            _SectionHeader(title: 'Income Statement'),
            const SizedBox(height: 8),
            _buildStatementTable(incomeStatements, _incomeStatementKeys),
            const SizedBox(height: 24),
          ],
          if (balanceSheets.isNotEmpty) ...[
            _SectionHeader(title: 'Balance Sheet'),
            const SizedBox(height: 8),
            _buildStatementTable(balanceSheets, _balanceSheetKeys),
            const SizedBox(height: 24),
          ],
          if (cashFlows.isNotEmpty) ...[
            _SectionHeader(title: 'Cash Flow'),
            const SizedBox(height: 8),
            _buildStatementTable(cashFlows, _cashFlowKeys),
            const SizedBox(height: 24),
          ],
          // Source attribution
          Text(
            'Source: SEC EDGAR · Last updated: ${_formatDate(DateTime.now())}',
            style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
          ),
        ],
      );
    });
  }

  Widget _buildStatementTable(List<StatementRow> rows, List<String> keys) {
    // Get unique periods (limit to 4 most recent)
    final periods = rows.map((r) => r.periodEnd).toSet().toList();
    periods.sort((a, b) => b.compareTo(a));
    final displayPeriods = periods.take(4).toList();

    // Filter rows to display periods
    final displayRows = <StatementRow>[];
    for (final period in displayPeriods) {
      final periodRows = rows.where((r) => r.periodEnd == period);
      if (periodRows.isNotEmpty) {
        displayRows.add(periodRows.first);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        columns: [
          const DataColumn(label: Text('')),
          ...displayPeriods.map((p) => DataColumn(
            label: Text(p.substring(0, 4), style: AppTypography.monoLabel),
            numeric: true,
          )),
        ],
        rows: keys.map((key) {
          return DataRow(
            cells: [
              DataCell(Text(_labelForKey(key), style: AppTypography.body)),
              ...displayRows.map((row) {
                final value = row.items[key];
                return DataCell(
                  Text(
                    value != null ? _formatValue(value) : '—',
                    style: AppTypography.monoData.copyWith(
                      color: value != null ? AppThemeColors.textPrimary : AppThemeColors.textTertiary,
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _labelForKey(String key) {
    switch (key) {
      case 'revenue': return 'Revenue';
      case 'gross_profit': return 'Gross Profit';
      case 'operating_income': return 'Operating Income';
      case 'net_income': return 'Net Income';
      case 'total_assets': return 'Total Assets';
      case 'total_liabilities': return 'Total Liabilities';
      case 'stockholders_equity': return 'Stockholders Equity';
      case 'cash_and_equivalents': return 'Cash & Equivalents';
      case 'operating_cash_flow': return 'Operating Cash Flow';
      case 'capex': return 'Capital Expenditure';
      case 'long_term_debt': return 'Long-Term Debt';
      case 'current_assets': return 'Current Assets';
      case 'current_liabilities': return 'Current Liabilities';
      default: return key;
    }
  }

  String _formatValue(double v) {
    if (v.abs() >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v.abs() >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v.abs() >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v.abs() >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static const _incomeStatementKeys = [
    'revenue', 'gross_profit', 'operating_income', 'net_income',
  ];

  static const _balanceSheetKeys = [
    'total_assets', 'total_liabilities', 'stockholders_equity',
    'cash_and_equivalents', 'long_term_debt',
    'current_assets', 'current_liabilities',
  ];

  static const _cashFlowKeys = [
    'operating_cash_flow', 'capex',
  ];
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: AppTypography.monoSection);
  }
}
