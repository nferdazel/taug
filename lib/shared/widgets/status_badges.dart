import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_badge.dart';

enum FreshnessStatus {
  fresh(label: 'Fresh', colorValue: 0xFF10B981, tooltip: 'Data updated within the last 30 days'),
  aging(label: 'Aging', colorValue: 0xFFF59E0B, tooltip: 'Data is 30-90 days old. May need refresh.'),
  stale(label: 'Stale', colorValue: 0xFFF43F5E, tooltip: 'Data is 90-365 days old. Consider verifying.'),
  expired(label: 'Expired', colorValue: 0xFF8E8E96, tooltip: 'Data is over 1 year old. Likely outdated.'),
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
  low(label: 'Low', colorValue: 0xFF8E8E96, tooltip: 'Low conviction. Early research stage.');

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

enum StanceBadgeSize { regular, small }

/// Thesis research freshness levels (7/30/90 day thresholds).
enum ResearchFreshness {
  fresh(label: 'Fresh', colorValue: 0xFF10B981, tooltip: 'Reviewed within the last 7 days'),
  aging(label: 'Aging', colorValue: 0xFFF59E0B, tooltip: 'Last review was 7-30 days ago. Consider reviewing.'),
  stale(label: 'Stale', colorValue: 0xFFF43F5E, tooltip: 'Last review was 30-90 days ago. Research may be outdated.'),
  expired(label: 'Expired', colorValue: 0xFF8E8E96, tooltip: 'Research is over 90 days old. Likely outdated.');

  final String label;
  final int colorValue;
  final String tooltip;
  const ResearchFreshness({required this.label, required this.colorValue, required this.tooltip});
  Color get color => Color(colorValue);

  /// Parse from a freshness string ('fresh', 'aging', 'stale', 'expired').
  static ResearchFreshness fromString(String? value) {
    return switch (value) {
      'fresh' => ResearchFreshness.fresh,
      'aging' => ResearchFreshness.aging,
      'stale' => ResearchFreshness.stale,
      'expired' => ResearchFreshness.expired,
      _ => ResearchFreshness.expired,
    };
  }
}

class ResearchFreshnessBadge extends StatelessWidget {
  final String? freshness;
  final DateTime? lastReviewedAt;

  const ResearchFreshnessBadge({
    super.key,
    this.freshness,
    this.lastReviewedAt,
  });

  @override
  Widget build(BuildContext context) {
    // Always prefer server-provided freshness string.
    // If not available, default to 'expired' — do NOT compute client-side
    // from lastReviewedAt to avoid build-time DateTime.now() calls.
    final String resolved = freshness ?? 'expired';

    final level = ResearchFreshness.fromString(resolved);
    return Semantics(
      label: 'Research freshness: ${level.label}',
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

class StanceBadge extends StatelessWidget {
  final String stance;
  final StanceBadgeSize size;

  const StanceBadge({super.key, required this.stance, this.size = StanceBadgeSize.regular});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (stance) {
      case 'bullish':
        color = AppThemeColors.success;
        label = 'Bullish';
      case 'bearish':
        color = AppThemeColors.critical;
        label = 'Bearish';
      default:
        color = AppThemeColors.neutral;
        label = 'Neutral';
    }

    final bool isSmall = size == StanceBadgeSize.small;
    final double hPad = isSmall ? 6 : 8;
    final double vPad = isSmall ? 2 : 3;
    final double fontSize = isSmall ? 10 : 11;
    final double radius = isSmall ? 3 : 4;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Priority badge for research questions.
/// Displays a colored label (LOW / MEDIUM / HIGH / CRITICAL).
class PriorityBadge extends StatelessWidget {
  final String priority;
  final Color color;

  const PriorityBadge({super.key, required this.priority, required this.color});

  /// Resolves the display color for a given priority string.
  static Color colorForPriority(String priority) {
    return switch (priority) {
      'critical' => AppThemeColors.critical,
      'high' => AppThemeColors.warning,
      'medium' => AppThemeColors.accent,
      _ => AppThemeColors.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppTypography.microBadge.copyWith(color: color),
      ),
    );
  }
}
