import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../../companies/presentation/widgets/research_status_badge.dart';
import '../providers/workspace_provider.dart';

class OverviewTab extends StatelessWidget {
  final WorkspaceProvider provider;

  const OverviewTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final profile = provider.profile.value;
      final metrics = provider.metrics;
      final theses = provider.theses;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Company Summary
          if (profile?.description != null) ...[
            const _SectionHeader(title: 'Company Summary'),
            const SizedBox(height: 8),
            Text(profile!.description!, style: AppTypography.body),
            const SizedBox(height: 24),
          ],

          // Key Metrics
          const _SectionHeader(title: 'Key Metrics'),
          const SizedBox(height: 8),
          _buildMetricsGrid(metrics),
          const SizedBox(height: 24),

          // Thesis Snapshot
          const _SectionHeader(title: 'Thesis Snapshot'),
          const SizedBox(height: 8),
          _buildThesisSnapshot(theses),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildMetricsGrid(List<dynamic> metrics) {
    final keyMetrics = [
      'market_cap',
      'pe',
      'roe',
      'gross_margin',
      'net_margin',
      'debt_equity',
    ];

    final metricMap = <String, dynamic>{};
    for (final m in metrics) {
      if (m.isOk && keyMetrics.contains(m.metricCode)) {
        metricMap[m.metricCode] = m;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keyMetrics.map((code) {
        final m = metricMap[code];
        if (m == null) {
          return _MetricCard(
            label: _metricLabel(code),
            value: '—',
            isOk: false,
            tooltip: _metricTooltip(code),
          );
        }
        return _MetricCard(
          label: m.metricName,
          value: _formatMetric(m),
          isOk: true,
          tooltip: _metricTooltip(code),
        );
      }).toList(),
    );
  }

  Widget _buildThesisSnapshot(List<dynamic> theses) {
    if (theses.isEmpty) {
      return Card(
        color: AppThemeColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('No thesis yet', style: AppTypography.caption),
              const SizedBox(height: 8),
              Text(
                'Create a thesis in the Research tab',
                style: AppTypography.caption.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final thesis = theses.first;
    return Card(
      color: AppThemeColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(thesis.title, style: AppTypography.subheading),
                ),
                ResearchStatusBadge(
                  status: ResearchStatus.fromString('researching'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StanceBadge(stance: thesis.stance),
                const SizedBox(width: 8),
                _ConvictionBadge(conviction: thesis.conviction),
              ],
            ),
            if (thesis.summary != null && thesis.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                thesis.summary!,
                style: AppTypography.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Updated: ${_formatDate(thesis.updatedAt)}',
              style: AppTypography.caption.copyWith(
                color: AppThemeColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metricLabel(String code) {
    switch (code) {
      case 'market_cap':
        return 'Market Cap';
      case 'pe':
        return 'PE';
      case 'roe':
        return 'ROE';
      case 'gross_margin':
        return 'Gross Margin';
      case 'net_margin':
        return 'Net Margin';
      case 'debt_equity':
        return 'D/E';
      default:
        return code;
    }
  }

  String _metricTooltip(String code) {
    switch (code) {
      case 'market_cap':
        return 'Total market value of outstanding shares. Share price × shares outstanding.';
      case 'pe':
        return 'Price-to-Earnings ratio. How much investors pay per dollar of earnings.';
      case 'roe':
        return 'Return on Equity. Profitability relative to shareholders\' equity.';
      case 'gross_margin':
        return 'Gross profit as % of revenue. Revenue remaining after cost of goods sold.';
      case 'net_margin':
        return 'Net income as % of revenue. Overall profitability after all expenses.';
      case 'debt_equity':
        return 'Total debt ÷ shareholders\' equity. Financial leverage measure.';
      default:
        return code;
    }
  }

  String _formatMetric(dynamic m) {
    if (m.valueNumeric == null) return '—';
    final v = m.valueNumeric as double;
    switch (m.unitType) {
      case 'percentage':
        return '${(v * 100).toStringAsFixed(2)}%';
      case 'monetary':
        return _formatLargeNumber(v);
      case 'ratio':
        return v.toStringAsFixed(2);
      default:
        return v.toStringAsFixed(2);
    }
  }

  String _formatLargeNumber(double n) {
    if (n.abs() >= 1e12) return '\$${(n / 1e12).toStringAsFixed(2)}T';
    if (n.abs() >= 1e9) return '\$${(n / 1e9).toStringAsFixed(2)}B';
    if (n.abs() >= 1e6) return '\$${(n / 1e6).toStringAsFixed(2)}M';
    if (n.abs() >= 1e3) return '\$${(n / 1e3).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;
  final String? tooltip;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.isOk,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      preferBelow: true,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppThemeColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppThemeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tooltip != null)
                  const Icon(Icons.info_outline, size: 10, color: AppThemeColors.textTertiary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.monoData.copyWith(
                color: isOk
                    ? AppThemeColors.textPrimary
                    : AppThemeColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StanceBadge extends StatelessWidget {
  final String stance;

  const _StanceBadge({required this.stance});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stance) {
      case 'bullish':
        color = AppThemeColors.success;
        label = 'Bullish';
        break;
      case 'bearish':
        color = AppThemeColors.critical;
        label = 'Bearish';
        break;
      default:
        color = AppThemeColors.neutral;
        label = 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ConvictionBadge extends StatelessWidget {
  final String conviction;

  const _ConvictionBadge({required this.conviction});

  @override
  Widget build(BuildContext context) {
    final level = ConvictionLevel.values.firstWhere(
      (l) => l.name == conviction,
      orElse: () => ConvictionLevel.low,
    );
    return ConvictionBadge(level: level);
  }
}
