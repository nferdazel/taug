import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/company/data/workspace_models.dart';

/// Shows a popover with quality score component breakdown.
/// Displays 7 component scores with color-coded progress bars.
class QualityBreakdownPopover extends StatelessWidget {
  final QualityScoreDetail quality;

  const QualityBreakdownPopover({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('DATA QUALITY', style: AppTypography.monoSection),
              const Spacer(),
              if (quality.scoreDate != null)
                Text(
                  'Scored: ${_formatDate(quality.scoreDate!)}',
                  style: AppTypography.monoMeta.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Overall score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemeColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border),
            ),
            child: Row(
              children: [
                Text(
                  'Overall',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _QualityScoreBadge(score: quality.overallScore),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Component scores
          _buildComponentRow('Historical Coverage', quality.historicalCoverageScore),
          const SizedBox(height: 8),
          _buildComponentRow('Completeness', quality.completenessScore),
          const SizedBox(height: 8),
          _buildComponentRow('Validation', quality.validationScore),
          const SizedBox(height: 8),
          _buildComponentRow('Verification', quality.verificationScore),
          const SizedBox(height: 8),
          _buildComponentRow('Freshness', quality.freshnessScore),
          const SizedBox(height: 8),
          _buildComponentRow('Restatement Support', quality.restatementSupportScore),
          // Component details
          if (quality.componentDetails != null && quality.componentDetails!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppThemeColors.border, height: 1),
            const SizedBox(height: 8),
            Text(
              'DETAILS',
              style: AppTypography.monoMeta.copyWith(
                color: AppThemeColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            ...quality.componentDetails!.entries.take(5).map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDetailKey(e.key),
                        style: AppTypography.caption,
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: AppTypography.monoMeta,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComponentRow(String label, double? score) {
    if (score == null) {
      return Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.caption),
          ),
          Text('N/A', style: AppTypography.monoMeta.copyWith(color: AppThemeColors.textTertiary)),
        ],
      );
    }

    final color = _getScoreColor(score);
    final percentage = (score * 100).toInt();

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: AppTypography.caption),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppThemeColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$percentage%',
            style: AppTypography.monoMeta.copyWith(color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppThemeColors.success;
    if (score >= 0.6) return AppThemeColors.warning;
    return AppThemeColors.critical;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatDetailKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Badge showing quality score with color coding.
class _QualityScoreBadge extends StatelessWidget {
  final double score;

  const _QualityScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final percentage = (score * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppThemeColors.success;
    if (score >= 0.6) return AppThemeColors.warning;
    return AppThemeColors.critical;
  }
}

/// Shows quality breakdown in a tooltip/popover.
/// Wrap any widget with this to show breakdown on tap.
class QualityBreakdownTooltip extends StatelessWidget {
  final QualityScoreDetail quality;
  final Widget child;

  const QualityBreakdownTooltip({
    super.key,
    required this.quality,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPopover(context),
      child: child,
    );
  }

  void _showPopover(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height + 400,
      ),
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: QualityBreakdownPopover(quality: quality),
        ),
      ],
    );
  }
}
