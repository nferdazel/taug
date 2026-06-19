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

  String toVolume() {
    if (this >= 1e9) {
      return '${(this / 1e9).toStringAsFixed(1)}B';
    } else if (this >= 1e6) {
      return '${(this / 1e6).toStringAsFixed(1)}M';
    } else if (this >= 1e3) {
      return '${(this / 1e3).toStringAsFixed(1)}K';
    }
    return toStringAsFixed(0);
  }
}

extension IntExtensions on int {
  String toVolume() {
    if (this >= 1e9) {
      return '${(this / 1e9).toStringAsFixed(1)}B';
    } else if (this >= 1e6) {
      return '${(this / 1e6).toStringAsFixed(1)}M';
    } else if (this >= 1e3) {
      return '${(this / 1e3).toStringAsFixed(1)}K';
    }
    return toString();
  }
}
