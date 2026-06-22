import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/research_progression_state.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';

class FinancialsTab extends StatefulWidget {
  final WorkspaceProvider provider;

  const FinancialsTab({super.key, required this.provider});

  @override
  State<FinancialsTab> createState() => _FinancialsTabState();
}

class _FinancialsTabState extends State<FinancialsTab> {
  bool _sidebarVisible = true;

  static const double _sidebarBreakpoint = 1200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= _sidebarBreakpoint;
        final bool showSidebar = isWide && _sidebarVisible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle button when below breakpoint or sidebar is hidden
            if (!isWide || !_sidebarVisible)
              _SidebarToggle(
                isExpanded: _sidebarVisible && !isWide,
                onTap: () => setState(() => _sidebarVisible = !_sidebarVisible),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Financial Statements
                  Expanded(
                    flex: showSidebar ? 7 : 1,
                    child: _buildStatements(),
                  ),
                  // Sidebar + Divider
                  if (showSidebar) ...[
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppThemeColors.border,
                    ),
                    Expanded(
                      flex: 3,
                      child: RepaintBoundary(
                        child: _buildResearchContextSidebar(widget.provider),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatements() {
    return SignalBuilder(builder: (_) {
      final statements = widget.provider.statements;

      if (statements.isEmpty) {
        return const Center(
          child: Text(
            'No financial data available',
            style: TextStyle(color: AppThemeColors.textTertiary),
          ),
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
            const _SectionHeader(title: 'Income Statement'),
            const SizedBox(height: 8),
            _buildStatementTable(incomeStatements, _incomeStatementKeys),
            const SizedBox(height: 24),
          ],
          if (balanceSheets.isNotEmpty) ...[
            const _SectionHeader(title: 'Balance Sheet'),
            const SizedBox(height: 8),
            _buildStatementTable(balanceSheets, _balanceSheetKeys),
            const SizedBox(height: 24),
          ],
          if (cashFlows.isNotEmpty) ...[
            const _SectionHeader(title: 'Cash Flow'),
            const SizedBox(height: 8),
            _buildStatementTable(cashFlows, _cashFlowKeys),
            const SizedBox(height: 24),
          ],
          // Source attribution
          Text(
            'Source: SEC EDGAR · Last updated: ${_formatDate(DateTime.now())}',
            style: AppTypography.caption.copyWith(
              color: AppThemeColors.textTertiary,
            ),
          ),
        ],
      );
    });
  }

  // ── Research Context Sidebar ──

  Widget _buildResearchContextSidebar(WorkspaceProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESEARCH CONTEXT', style: AppTypography.monoSection),
          const SizedBox(height: 12),
          _buildFreshnessCard(provider),
          const SizedBox(height: 12),
          _buildCoverageCard(provider),
          const SizedBox(height: 12),
          _buildRestatementCard(provider),
          const SizedBox(height: 12),
          _buildNextStepsCard(provider),
        ],
      ),
    );
  }

  /// Freshness Card — data as-of date, last filing date, freshness status.
  Widget _buildFreshnessCard(WorkspaceProvider provider) {
    return SignalBuilder(builder: (_) {
      final String freshnessLabel;
      final Color freshnessColor;
      final String status = provider.freshnessStatus.value ?? 'unknown';

      switch (status) {
        case 'fresh':
          freshnessLabel = 'Fresh';
          freshnessColor = AppThemeColors.bullish;
        case 'aging':
          freshnessLabel = 'Aging';
          freshnessColor = AppThemeColors.warning;
        case 'stale':
          freshnessLabel = 'Stale';
          freshnessColor = AppThemeColors.bearish;
        case 'expired':
          freshnessLabel = 'Expired';
          freshnessColor = AppThemeColors.critical;
        default:
          freshnessLabel = 'Unknown';
          freshnessColor = AppThemeColors.textTertiary;
      }

      // Derive the most recent period end date from statements as as-of date
      final statements = provider.statements;
      String asOfDate = '—';
      String lastFilingDate = '—';
      if (statements.isNotEmpty) {
        final sortedPeriods = statements.map((s) => s.periodEnd).toList()
          ..sort((a, b) => b.compareTo(a));
        asOfDate = sortedPeriods.first;

        // Use the highest version statement's period as a proxy for last filing
        final maxVersionRow = statements
            .where((s) => s.statementVersion != null)
            .fold<StatementRow?>(null, (prev, curr) {
          if (prev == null) return curr;
          return (curr.statementVersion ?? 0) > (prev.statementVersion ?? 0)
              ? curr
              : prev;
        });
        if (maxVersionRow != null) {
          lastFilingDate = maxVersionRow.periodEnd;
        }
      }

      return _SidebarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('FRESHNESS', style: AppTypography.monoSection),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: freshnessColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    freshnessLabel,
                    style: AppTypography.microBadge.copyWith(
                      color: freshnessColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _sidebarRow('Data as-of', asOfDate),
            const SizedBox(height: 6),
            _sidebarRow('Last filing', lastFilingDate),
          ],
        ),
      );
    });
  }

  /// Coverage Card — quality score with component bars.
  Widget _buildCoverageCard(WorkspaceProvider provider) {
    return SignalBuilder(builder: (_) {
      final QualityScoreDetail? detail = provider.qualityDetail.value;
      final double overall = detail?.overallScore ?? 0.0;

      return _SidebarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('COVERAGE', style: AppTypography.monoSection),
                const Spacer(),
                Text(
                  '${(overall * 100).toStringAsFixed(0)}%',
                  style: AppTypography.monoData.copyWith(
                    color: _scoreColor(overall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (detail != null) ...[
              _scoreBar(
                'Historical',
                detail.historicalCoverageScore,
              ),
              const SizedBox(height: 6),
              _scoreBar('Completeness', detail.completenessScore),
              const SizedBox(height: 6),
              _scoreBar('Validation', detail.validationScore),
              const SizedBox(height: 6),
              _scoreBar('Verification', detail.verificationScore),
              const SizedBox(height: 6),
              _scoreBar('Freshness', detail.freshnessScore),
            ] else
              Text(
                'No quality data',
                style: AppTypography.caption.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Restatement Card — count of restated statements.
  Widget _buildRestatementCard(WorkspaceProvider provider) {
    return SignalBuilder(builder: (_) {
      final statements = provider.statements;
      final int restatedCount =
          statements.where((s) => s.isRestated).length;
      final int totalVersions = statements
          .where((s) => s.statementVersion != null && s.statementVersion! > 1)
          .length;

      return _SidebarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RESTATEMENTS', style: AppTypography.monoSection),
            const SizedBox(height: 10),
            _sidebarRow(
              'Restated',
              '$restatedCount',
              valueColor:
                  restatedCount > 0 ? AppThemeColors.warning : null,
            ),
            const SizedBox(height: 6),
            _sidebarRow('Revised versions', '$totalVersions'),
          ],
        ),
      );
    });
  }

  /// Next Steps Card — open questions, thesis freshness, actionable prompts.
  Widget _buildNextStepsCard(WorkspaceProvider provider) {
    return SignalBuilder(builder: (_) {
      final progression = provider.progressionState;
      final int openQuestions = progression.openQuestionsCount;
      final String? thesisFreshness = progression.researchFreshness;

      final String freshnessLabel;
      final Color freshnessColor;
      switch (thesisFreshness) {
        case 'fresh':
          freshnessLabel = 'Fresh';
          freshnessColor = AppThemeColors.bullish;
        case 'aging':
          freshnessLabel = 'Aging';
          freshnessColor = AppThemeColors.warning;
        case 'stale':
          freshnessLabel = 'Stale';
          freshnessColor = AppThemeColors.bearish;
        case 'expired':
          freshnessLabel = 'Expired';
          freshnessColor = AppThemeColors.critical;
        default:
          freshnessLabel = '—';
          freshnessColor = AppThemeColors.textTertiary;
      }

      final NextAction action = progression.nextAction;

      return _SidebarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEXT STEPS', style: AppTypography.monoSection),
            const SizedBox(height: 10),
            _sidebarRow(
              'Open questions',
              '$openQuestions',
              valueColor:
                  openQuestions > 0 ? AppThemeColors.warning : null,
            ),
            const SizedBox(height: 6),
            _sidebarRow(
              'Thesis freshness',
              freshnessLabel,
              valueColor: freshnessColor,
            ),
            if (action != NextAction.none) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: const Border(
                    left: BorderSide(
                      color: AppThemeColors.accent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: AppTypography.body.copyWith(
                        color: AppThemeColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Sidebar Helpers ──

  /// Horizontal label-value row used in sidebar cards.
  static Widget _sidebarRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption,
        ),
        Text(
          value,
          style: AppTypography.monoLabel.copyWith(
            color: valueColor ?? AppThemeColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// A fractional score bar with label.
  static Widget _scoreBar(String label, double? score) {
    final double value = score ?? 0.0;
    final Color color = _scoreColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.micro),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: AppTypography.monoMeta.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppThemeColors.surfaceMuted,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Maps a 0–1 score to a color: green ≥0.7, amber ≥0.4, red below.
  static Color _scoreColor(double score) {
    if (score >= 0.7) return AppThemeColors.bullish;
    if (score >= 0.4) return AppThemeColors.warning;
    return AppThemeColors.bearish;
  }

  // ── Statement Table (unchanged) ──

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
          ...displayRows.map(
            (row) => DataColumn(
              label: _PeriodHeader(row: row),
              numeric: true,
            ),
          ),
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
                      color: value != null
                          ? AppThemeColors.textPrimary
                          : AppThemeColors.textTertiary,
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
      case 'revenue':
        return 'Revenue';
      case 'gross_profit':
        return 'Gross Profit';
      case 'operating_income':
        return 'Operating Income';
      case 'net_income':
        return 'Net Income';
      case 'total_assets':
        return 'Total Assets';
      case 'total_liabilities':
        return 'Total Liabilities';
      case 'stockholders_equity':
        return 'Stockholders Equity';
      case 'cash_and_equivalents':
        return 'Cash & Equivalents';
      case 'operating_cash_flow':
        return 'Operating Cash Flow';
      case 'capex':
        return 'Capital Expenditure';
      case 'long_term_debt':
        return 'Long-Term Debt';
      case 'current_assets':
        return 'Current Assets';
      case 'current_liabilities':
        return 'Current Liabilities';
      default:
        return key;
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

  static const List<String> _incomeStatementKeys = [
    'revenue',
    'gross_profit',
    'operating_income',
    'net_income',
  ];

  static const List<String> _balanceSheetKeys = [
    'total_assets',
    'total_liabilities',
    'stockholders_equity',
    'cash_and_equivalents',
    'long_term_debt',
    'current_assets',
    'current_liabilities',
  ];

  static const List<String> _cashFlowKeys = ['operating_cash_flow', 'capex'];
}

/// Builds a period header with restatement indicator, version badge, and
/// freshness tint based on the statement's age.
class _PeriodHeader extends StatelessWidget {
  final StatementRow row;

  const _PeriodHeader({required this.row});

  @override
  Widget build(BuildContext context) {
    final Color? backgroundColor = _freshnessTint();

    return Tooltip(
      message: row.isRestated
          ? 'This statement has been restated by the company'
          : _periodDisplayText(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Version badge when version > 1
            if (row.statementVersion != null && row.statementVersion! > 1)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppThemeColors.textTertiary,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'v${row.statementVersion}',
                    style: AppTypography.monoMeta.copyWith(
                      fontSize: 8,
                      color: AppThemeColors.textTertiary,
                    ),
                  ),
                ),
              ),
            // Period year label
            Text(
              row.periodEnd.substring(0, 4),
              style: AppTypography.monoLabel,
            ),
            // Restatement indicator
            if (row.isRestated)
              const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Icon(
                  Icons.sync,
                  size: 11,
                  color: AppThemeColors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Returns the period end year as display text.
  String _periodDisplayText() {
    try {
      return row.periodEnd.substring(0, 4);
    } catch (e) {
      debugPrint('[FinancialsTab] periodDisplayText parse error: $e');
      return row.periodEnd;
    }
  }

  /// Computes a subtle background tint based on the age of the period end date.
  /// - < 90 days: no tint (null)
  /// - 90–365 days: amber tint (warning at low alpha)
  /// - > 365 days: red tint (critical at low alpha)
  Color? _freshnessTint() {
    try {
      final DateTime periodDate = DateTime.parse(row.periodEnd);
      final int ageDays = DateTime.now().difference(periodDate).inDays;

      if (ageDays < 90) return null;
      if (ageDays <= 365) {
        return AppThemeColors.warning.withAlpha(20);
      }
      return AppThemeColors.critical.withAlpha(18);
    } catch (e) {
      debugPrint('[FinancialsTab] freshnessTint parse error: $e');
      return null;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: AppTypography.monoSection);
  }
}

/// Reusable card container for sidebar sections.
class _SidebarCard extends StatelessWidget {
  final Widget child;

  const _SidebarCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: child,
    );
  }
}

/// Toggle button shown when sidebar is collapsed or viewport is narrow.
class _SidebarToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarToggle({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppThemeColors.border, width: 1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpanded ? Icons.chevron_right : Icons.chevron_left,
              size: 16,
              color: AppThemeColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isExpanded ? 'HIDE CONTEXT' : 'SHOW CONTEXT',
              style: AppTypography.monoSection,
            ),
          ],
        ),
      ),
    );
  }
}
