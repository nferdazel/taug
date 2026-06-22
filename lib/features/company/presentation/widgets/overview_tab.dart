import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/research_progression_state.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';

class OverviewTab extends StatelessWidget {
  final WorkspaceProvider provider;

  const OverviewTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (_) {
      final profile = provider.profile.value;
      final metrics = provider.metrics;
      final qualityDetail = provider.qualityDetail.value;
      final freshness = provider.freshnessStatus.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next action — primary decision guidance
            _buildNextAction(context),
            const SizedBox(height: 24),

            // Research snapshot — progression overview
            _buildResearchSnapshot(context),
            const SizedBox(height: 24),

            // Data trust summary
            _buildDataTrustSection(qualityDetail, freshness),
            const SizedBox(height: 24),

            // Key metrics — supporting
            _buildMetricsSection(metrics, qualityDetail, freshness),
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

  Widget _buildNextAction(BuildContext context) {
    final progression = provider.progressionState;
    final action = progression.nextAction;

    if (action == NextAction.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeColors.accent.withValues(alpha: 0.1),
        border: const Border(left: BorderSide(color: AppThemeColors.accent, width: 3)),
      ),
      child: Row(
        children: [
          Text(action.icon, style: AppTypography.body),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.label, style: AppTypography.subheading),
                Text(action.description, style: AppTypography.caption),
              ],
            ),
          ),
          _buildNextActionButton(context, action),
        ],
      ),
    );
  }

  Widget _buildNextActionButton(BuildContext context, NextAction action) {
    final VoidCallback? onPressed;
    final String label;

    switch (action) {
      case NextAction.createNote:
      case NextAction.createThesis:
      case NextAction.answerQuestions:
        onPressed = () => provider.activeTab.value = 2;
        label = action.label;
      case NextAction.createPosition:
        onPressed = () => context.go('/portfolio-workspace');
        label = action.label;
      case NextAction.reviewThesis:
        onPressed = () => provider.activeTab.value = 2;
        label = action.label;
      case NextAction.reviewFiling:
        onPressed = null;
        label = action.label;
      case NextAction.none:
        return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppThemeColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppThemeColors.accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppThemeColors.accent,
          ),
        ),
      ),
    );
  }

  // ── Research Snapshot ──

  Widget _buildResearchSnapshot(BuildContext context) {
    final progression = provider.progressionState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RESEARCH SNAPSHOT', style: AppTypography.monoSection),
        const SizedBox(height: 8),
        Row(
          children: [
            _SnapshotCell(
              label: 'THESIS',
              value: progression.thesesCount > 0
                  ? '${progression.thesisStance ?? "Unknown"} / ${progression.thesisConviction ?? "Low"}'
                  : 'None',
              isEmpty: progression.thesesCount == 0,
              actionLabel: progression.thesesCount == 0 ? 'Create thesis' : null,
              onAction: progression.thesesCount == 0
                  ? () => provider.activeTab.value = 2
                  : null,
            ),
            _SnapshotCell(
              label: 'NOTES',
              value: '${progression.notesCount} items',
              isEmpty: progression.notesCount == 0,
              actionLabel: progression.notesCount == 0 ? 'Create note' : null,
              onAction: progression.notesCount == 0
                  ? () => provider.activeTab.value = 2
                  : null,
            ),
            _SnapshotCell(
              label: 'QUESTIONS',
              value: progression.openQuestionsCount > 0
                  ? '${progression.openQuestionsCount} open'
                  : 'None',
              isEmpty: progression.openQuestionsCount == 0,
              actionLabel: progression.openQuestionsCount == 0 ? 'Add question' : null,
              onAction: progression.openQuestionsCount == 0
                  ? () => provider.activeTab.value = 2
                  : null,
            ),
            _SnapshotCell(
              label: 'POSITION',
              value: progression.positionsCount > 0 ? 'Active' : 'None',
              isEmpty: progression.positionsCount == 0,
              actionLabel: progression.positionsCount == 0 && progression.thesesCount > 0
                  ? 'Create position'
                  : null,
              onAction: progression.positionsCount == 0 && progression.thesesCount > 0
                  ? () => context.go('/portfolio-workspace')
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  // ── Data Trust Section ──

  Widget _buildDataTrustSection(QualityScoreDetail? quality, String? freshness) {
    // Don't render if both are null — no trust data available
    if (quality == null && freshness == null) return const SizedBox.shrink();

    final freshnessInfo = _resolveFreshnessInfo(freshness);
    final qualityInfo = _resolveQualityInfo(quality);

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
                Icon(Icons.verified_outlined, size: 14, color: AppThemeColors.textSecondary),
                SizedBox(width: 8),
                Text('DATA TRUST', style: AppTypography.monoSection),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Quality badge
                if (qualityInfo != null) ...[
                  _TrustBadge(
                    icon: Icons.analytics_outlined,
                    label: 'Quality',
                    value: qualityInfo.label,
                    color: qualityInfo.color,
                  ),
                  const SizedBox(width: 16),
                ],
                // Freshness badge
                _TrustBadge(
                  icon: Icons.schedule,
                  label: 'Statements',
                  value: freshnessInfo.label,
                  color: freshnessInfo.color,
                ),
                const Spacer(),
                // As-of date
                if (quality?.scoreDate != null)
                  Text(
                    'Scored ${quality!.scoreDate!.toMmDdYyyy()}',
                    style: AppTypography.monoMeta.copyWith(color: AppThemeColors.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FreshnessInfo _resolveFreshnessInfo(String? freshness) {
    if (freshness == null) {
      return const _FreshnessInfo(label: 'Unknown', color: AppThemeColors.textTertiary);
    }
    switch (freshness.toLowerCase()) {
      case 'fresh':
      case 'current':
      case 'up_to_date':
        return const _FreshnessInfo(label: 'Fresh', color: AppThemeColors.success);
      case 'recent':
        return const _FreshnessInfo(label: 'Recent', color: AppThemeColors.success);
      case 'aging':
      case 'moderate':
        return const _FreshnessInfo(label: 'Aging', color: AppThemeColors.warning);
      case 'stale':
      case 'old':
      case 'outdated':
        return const _FreshnessInfo(label: 'Stale', color: AppThemeColors.critical);
      default:
        return _FreshnessInfo(label: _humanize(freshness), color: AppThemeColors.textTertiary);
    }
  }

  _QualityInfo? _resolveQualityInfo(QualityScoreDetail? quality) {
    if (quality == null) return null;
    final score = quality.overallScore;
    final label = '${(score * 100).toStringAsFixed(0)}%';
    final Color color;
    if (score >= 0.8) {
      color = AppThemeColors.success;
    } else if (score >= 0.5) {
      color = AppThemeColors.warning;
    } else {
      color = AppThemeColors.critical;
    }
    return _QualityInfo(label: label, color: color);
  }

  // ── Metrics Section ──

  Widget _buildMetricsSection(
    List<dynamic> metrics,
    QualityScoreDetail? quality,
    String? freshness,
  ) {
    final keyMetrics = ['market_cap', 'pe', 'roe', 'gross_margin', 'net_margin', 'debt_equity'];
    final metricMap = <String, dynamic>{};
    for (final m in metrics) {
      if (m.isOk && keyMetrics.contains(m.metricCode)) {
        metricMap[m.metricCode] = m;
      }
    }

    final freshnessColor = _resolveFreshnessInfo(freshness).color;
    final DateTime? asOfDate = quality?.scoreDate;

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
            childAspectRatio: 2.0,
            children: keyMetrics.map((code) {
              final m = metricMap[code];
              return RepaintBoundary(
                child: _MetricCell(
                  label: _metricLabel(code),
                  value: m != null ? _formatMetric(m) : '—',
                  isOk: m != null,
                  tooltip: _metricTooltip(code),
                  freshnessBorderColor: freshnessColor,
                  asOfDate: asOfDate,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Metric Helpers ──

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
      case 'debt_equity': return 'Total debt / shareholders equity.';
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

  String _humanize(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

// ── Data Models ──

class _FreshnessInfo {
  final String label;
  final Color color;

  const _FreshnessInfo({required this.label, required this.color});
}

class _QualityInfo {
  final String label;
  final Color color;

  const _QualityInfo({required this.label, required this.color});
}

// ── Trust Badge Widget ──

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.monoMeta.copyWith(fontSize: 10)),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTypography.mono,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Snapshot Cell Widget ──

class _SnapshotCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmpty;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnapshotCell({
    required this.label,
    required this.value,
    required this.isEmpty,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppThemeColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.monoSection),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.monoData.copyWith(
                color: isEmpty ? AppThemeColors.textTertiary : AppThemeColors.textPrimary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppThemeColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Metric Cell (with freshness indicators) ──

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;
  final String? tooltip;
  final Color freshnessBorderColor;
  final DateTime? asOfDate;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.isOk,
    this.tooltip,
    required this.freshnessBorderColor,
    this.asOfDate,
  });

  @override
  Widget build(BuildContext context) {
    final String? asOfText = asOfDate != null
        ? 'as of ${asOfDate!.month.toString().padLeft(2, '0')}/${asOfDate!.day.toString().padLeft(2, '0')}/${asOfDate!.year}'
        : null;

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
            left: BorderSide(color: freshnessBorderColor, width: 2),
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
            if (asOfText != null) ...[
              const SizedBox(height: 2),
              Text(
                asOfText,
                style: AppTypography.monoMeta.copyWith(
                  fontSize: 9,
                  color: AppThemeColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
