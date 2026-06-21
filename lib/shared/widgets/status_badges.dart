import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_badge.dart';

enum FreshnessStatus {
  fresh(label: 'Fresh', colorValue: 0xFF10B981, tooltip: 'Data updated within the last 30 days'),
  aging(label: 'Aging', colorValue: 0xFFF59E0B, tooltip: 'Data is 30-90 days old. May need refresh.'),
  stale(label: 'Stale', colorValue: 0xFFF43F5E, tooltip: 'Data is 90-365 days old. Consider verifying.'),
  expired(label: 'Expired', colorValue: 0xFF71717A, tooltip: 'Data is over 1 year old. Likely outdated.'),
  unknown(label: '—', colorValue: 0xFF52525B, tooltip: 'No freshness data available.');

  final String label;
  final int colorValue;
  final String tooltip;
  const FreshnessStatus({required this.label, required this.colorValue, required this.tooltip});
  Color get color => Color(colorValue);
}

class FreshnessBadge extends StatelessWidget {
  final FreshnessStatus status;

  const FreshnessBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == FreshnessStatus.unknown) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: 'Freshness: ${status.label}',
      child: Tooltip(
        message: status.tooltip,
        preferBelow: true,
        decoration: BoxDecoration(
          color: AppThemeColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppThemeColors.border),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
        child: AppBadge(
          label: status.label,
          color: status.color,
          icon: Icons.circle,
        ),
      ),
    );
  }
}

enum QualityLevel {
  high(label: 'High', threshold: 0.8, colorValue: 0xFF10B981, tooltip: 'Data quality score ≥ 80%. Reliable for analysis.'),
  medium(label: 'Medium', threshold: 0.6, colorValue: 0xFFF59E0B, tooltip: 'Data quality score 60-80%. Use with caution.'),
  low(label: 'Low', threshold: 0.0, colorValue: 0xFFF43F5E, tooltip: 'Data quality score < 60%. Verify before use.'),
  unknown(label: '—', threshold: 0.0, colorValue: 0xFF52525B, tooltip: 'No quality data available.');

  final String label;
  final double threshold;
  final int colorValue;
  final String tooltip;
  const QualityLevel({required this.label, required this.threshold, required this.colorValue, required this.tooltip});
  Color get color => Color(colorValue);

  static QualityLevel fromScore(double? score) {
    if (score == null) return QualityLevel.unknown;
    if (score >= 0.8) return QualityLevel.high;
    if (score >= 0.6) return QualityLevel.medium;
    return QualityLevel.low;
  }
}

class QualityBadge extends StatelessWidget {
  final double? score;

  const QualityBadge({super.key, this.score});

  @override
  Widget build(BuildContext context) {
    final level = QualityLevel.fromScore(score);
    if (level == QualityLevel.unknown) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: 'Quality: ${level.label} ${(score! * 100).round()} percent',
      child: Tooltip(
        message: level.tooltip,
        preferBelow: true,
        decoration: BoxDecoration(
          color: AppThemeColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppThemeColors.border),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
        child: AppBadge(
          label: '${(score! * 100).round()}%',
          color: level.color,
          icon: Icons.circle,
        ),
      ),
    );
  }
}

enum ConvictionLevel {
  high(label: 'High', colorValue: 0xFF3B82F6, tooltip: 'Strong conviction in this investment thesis.'),
  medium(label: 'Medium', colorValue: 0xFFF59E0B, tooltip: 'Moderate conviction. Thesis is forming.'),
  low(label: 'Low', colorValue: 0xFF71717A, tooltip: 'Low conviction. Early research stage.');

  final String label;
  final int colorValue;
  final String tooltip;
  const ConvictionLevel({required this.label, required this.colorValue, required this.tooltip});
  Color get color => Color(colorValue);
}

class ConvictionBadge extends StatelessWidget {
  final ConvictionLevel level;

  const ConvictionBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Conviction: ${level.label}',
      child: Tooltip(
        message: level.tooltip,
        preferBelow: true,
        decoration: BoxDecoration(
          color: AppThemeColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppThemeColors.border),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
        child: AppBadge(
          label: level.label,
          color: level.color,
          icon: Icons.circle,
        ),
      ),
    );
  }
}
