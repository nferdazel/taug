extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get upperCaseAll => toUpperCase();

  String get lowerCaseAll => toLowerCase();
}

extension DoubleExtensions on double {
  String toPrice({int decimals = 2}) {
    return toStringAsFixed(decimals);
  }

  String toPercent({int decimals = 2}) {
    final sign = this >= 0 ? '+' : '';
    return '$sign${toStringAsFixed(decimals)}%';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format as yyyy-MM-dd (e.g. 2025-01-05).
  String toYyyyMmDd() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Format as MM/dd/yyyy (e.g. 01/05/2025).
  String toMmDdYyyy() {
    return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/$year';
  }

  /// Human-readable relative time (e.g. "5m ago", "3h ago", "2d ago").
  /// Pass [short] for compact labels without " ago" suffix.
  String timeAgo({bool short = false}) {
    final Duration diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return short ? 'now' : 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m${short ? '' : ' ago'}';
    if (diff.inHours < 24) return '${diff.inHours}h${short ? '' : ' ago'}';
    if (diff.inDays < 30) return '${diff.inDays}d${short ? '' : ' ago'}';
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo${short ? '' : ' ago'}';
    }
    return '${(diff.inDays / 365).floor()}y${short ? '' : ' ago'}';
  }
}

String formatVolume(num value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  } else if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

/// Extracts a nested relation row from a Supabase join result.
/// Handles both direct map and single-element list representations.
Map<String, dynamic>? extractRelationRow(
  Map<String, dynamic> row,
  String relationKey,
) {
  final Object? relation = row[relationKey];
  if (relation is Map<String, dynamic>) {
    return relation;
  }
  if (relation is List && relation.isNotEmpty && relation.first is Map) {
    return Map<String, dynamic>.from(relation.first as Map);
  }
  return null;
}
