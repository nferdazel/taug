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
