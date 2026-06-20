import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
      final notes = provider.notes;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decision prompt — primary object
            _buildDecisionPrompt(theses, notes),
            const SizedBox(height: 24),

            // Research state — secondary
            _buildResearchState(theses, notes),
            const SizedBox(height: 24),

            // Key metrics — supporting
            _buildMetricsSection(metrics),
            const SizedBox(height: 24),

            // Company summary — background
            if (profile?.description != null) ...[
              const Text('ABOUT', style: AppTypography.monoSection),
              const SizedBox(height: 8),
              Text(profile!.description!, style: AppTypography.body),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDecisionPrompt(List<dynamic> theses, List<dynamic> notes) {
    final status = _getResearchStatus(theses, notes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(status.icon, size: 20, color: status.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.title, style: AppTypography.subheading.copyWith(color: status.color)),
                const SizedBox(height: 2),
                Text(status.description, style: AppTypography.caption),
              ],
            ),
          ),
          if (status.actionLabel != null)
            _ActionChip(
              label: status.actionLabel!,
              color: status.color,
            ),
        ],
      ),
    );
  }

  Widget _buildResearchState(List<dynamic> theses, List<dynamic> notes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppThemeColors.surfaceMuted,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, size: 14, color: AppThemeColors.textSecondary),
                SizedBox(width: 8),
                Text('RESEARCH STATE', style: AppTypography.monoSection),
              ],
            ),
          ),
          // Thesis
          if (theses.isNotEmpty)
            _buildThesisRow(theses.first)
          else
            _buildEmptyRow(Icons.lightbulb_outline, 'No thesis', 'Create a thesis to formalize your investment thesis'),
          // Notes
          if (notes.isNotEmpty)
            _buildNotesSummary(notes)
          else
            _buildEmptyRow(Icons.note_outlined, 'No notes', 'Start documenting your research'),
        ],
      ),
    );
  }

  Widget _buildThesisRow(dynamic thesis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StanceChip(stance: thesis.stance),
              const SizedBox(width: 8),
              _ConvictionChip(conviction: thesis.conviction),
              const SizedBox(width: 8),
              Expanded(
                child: Text(thesis.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (thesis.summary != null && thesis.summary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(thesis.summary!, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSummary(List<dynamic> notes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.note_outlined, size: 14, color: AppThemeColors.textTertiary),
          const SizedBox(width: 8),
          Text('${notes.length} research notes', style: AppTypography.caption),
          const Spacer(),
          Text(
            'Latest: ${_formatDate(notes.first.updatedAt)}',
            style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppThemeColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body.copyWith(color: AppThemeColors.textTertiary)),
                Text(description, style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(List<dynamic> metrics) {
    final keyMetrics = ['market_cap', 'pe', 'roe', 'gross_margin', 'net_margin', 'debt_equity'];
    final metricMap = <String, dynamic>{};
    for (final m in metrics) {
      if (m.isOk && keyMetrics.contains(m.metricCode)) {
        metricMap[m.metricCode] = m;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppThemeColors.surfaceMuted,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.insights, size: 14, color: AppThemeColors.textSecondary),
                SizedBox(width: 8),
                Text('KEY METRICS', style: AppTypography.monoSection),
              ],
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            children: keyMetrics.map((code) {
              final m = metricMap[code];
              return _MetricCell(
                label: _metricLabel(code),
                value: m != null ? _formatMetric(m) : '—',
                isOk: m != null,
                tooltip: _metricTooltip(code),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  _ResearchStatus _getResearchStatus(List<dynamic> theses, List<dynamic> notes) {
    if (theses.isNotEmpty) {
      return _ResearchStatus(
        title: 'Thesis Active',
        description: 'Thesis "${theses.first.title}" is active. Consider updating or creating a position.',
        icon: Icons.lightbulb,
        color: AppThemeColors.success,
        actionLabel: 'Review Thesis',
      );
    }
    if (notes.isNotEmpty) {
      return _ResearchStatus(
        title: 'Research in Progress',
        description: '${notes.length} notes created. Consider formalizing your research into a thesis.',
        icon: Icons.edit_note,
        color: AppThemeColors.accent,
        actionLabel: 'Create Thesis',
      );
    }
    return _ResearchStatus(
      title: 'Not Yet Researched',
      description: 'Start by creating research notes about this company.',
      icon: Icons.science_outlined,
      color: AppThemeColors.textTertiary,
      actionLabel: 'Create Note',
    );
  }

  String _metricLabel(String code) {
    switch (code) {
      case 'market_cap': return 'Market Cap';
      case 'pe': return 'PE';
      case 'roe': return 'ROE';
      case 'gross_margin': return 'Gross Margin';
      case 'net_margin': return 'Net Margin';
      case 'debt_equity': return 'D/E';
      default: return code;
    }
  }

  String _metricTooltip(String code) {
    switch (code) {
      case 'market_cap': return 'Total market value of outstanding shares.';
      case 'pe': return 'Price-to-Earnings ratio.';
      case 'roe': return 'Return on Equity.';
      case 'gross_margin': return 'Gross profit as % of revenue.';
      case 'net_margin': return 'Net income as % of revenue.';
      case 'debt_equity': return 'Total debt ÷ shareholders equity.';
      default: return code;
    }
  }

  String _formatMetric(dynamic m) {
    if (m.valueNumeric == null) return '—';
    final v = m.valueNumeric as double;
    switch (m.unitType) {
      case 'percentage': return '${(v * 100).toStringAsFixed(2)}%';
      case 'monetary': return _formatLargeNumber(v);
      case 'ratio': return v.toStringAsFixed(2);
      default: return v.toStringAsFixed(2);
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
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

class _ResearchStatus {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionLabel;

  _ResearchStatus({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
  });
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ActionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;
  final String? tooltip;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.isOk,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5)),
            bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.monoPrice.copyWith(
                color: isOk ? AppThemeColors.textPrimary : AppThemeColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StanceChip extends StatelessWidget {
  final String stance;

  const _StanceChip({required this.stance});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stance) {
      case 'bullish': color = AppThemeColors.success; label = 'Bullish';
      case 'bearish': color = AppThemeColors.critical; label = 'Bearish';
      default: color = AppThemeColors.neutral; label = 'Neutral';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ConvictionChip extends StatelessWidget {
  final String conviction;

  const _ConvictionChip({required this.conviction});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (conviction) {
      case 'high': color = AppThemeColors.accent;
      case 'medium': color = AppThemeColors.warning;
      default: color = AppThemeColors.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        conviction[0].toUpperCase() + conviction.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
