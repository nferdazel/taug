import 'package:flutter/material.dart';

import 'app_badge.dart';

enum FreshnessStatus {
  fresh(label: 'Fresh', colorValue: 0xFF10B981),
  aging(label: 'Aging', colorValue: 0xFFF59E0B),
  stale(label: 'Stale', colorValue: 0xFFF43F5E),
  expired(label: 'Expired', colorValue: 0xFF71717A),
  unknown(label: '—', colorValue: 0xFF52525B);

  final String label;
  final int colorValue;
  const FreshnessStatus({required this.label, required this.colorValue});
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
    return AppBadge(
      label: status.label,
      color: status.color,
      icon: Icons.circle,
    );
  }
}

enum QualityLevel {
  high(label: 'High', threshold: 0.8, colorValue: 0xFF10B981),
  medium(label: 'Medium', threshold: 0.6, colorValue: 0xFFF59E0B),
  low(label: 'Low', threshold: 0.0, colorValue: 0xFFF43F5E),
  unknown(label: '—', threshold: 0.0, colorValue: 0xFF52525B);

  final String label;
  final double threshold;
  final int colorValue;
  const QualityLevel({required this.label, required this.threshold, required this.colorValue});
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
    return AppBadge(
      label: '${(score! * 100).round()}%',
      color: level.color,
      icon: Icons.circle,
    );
  }
}

enum ConvictionLevel {
  high(label: 'High', colorValue: 0xFF3B82F6),
  medium(label: 'Medium', colorValue: 0xFFF59E0B),
  low(label: 'Low', colorValue: 0xFF71717A);

  final String label;
  final int colorValue;
  const ConvictionLevel({required this.label, required this.colorValue});
  Color get color => Color(colorValue);
}

class ConvictionBadge extends StatelessWidget {
  final ConvictionLevel level;

  const ConvictionBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: level.label,
      color: level.color,
      icon: Icons.circle,
    );
  }
}
