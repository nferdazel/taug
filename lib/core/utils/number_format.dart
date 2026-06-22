// Centralized number formatting utilities for financial data display.
//
// All financial terminals MUST use these formatters to ensure consistent
// presentation of currency, percentages, and large numbers across the app.

/// Format large numbers with compact currency notation.
///
/// Examples:
/// - 1234567890 → "$1.2B"
/// - 1234567    → "$1.2M"
/// - 1234       → "$1.2K"
/// - 50.25      → "$50.25"
String formatCurrency(double value) {
  if (value.abs() >= 1e12) return '\$${(value / 1e12).toStringAsFixed(1)}T';
  if (value.abs() >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
  if (value.abs() >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
  if (value.abs() >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
  return '\$${value.toStringAsFixed(2)}';
}

/// Format a decimal fraction as a signed percentage string.
///
/// Examples:
/// - 0.1234  → "+12.34%"
/// - -0.0567 → "-5.67%"
/// - 0.0     → "+0.00%"
String formatPercent(double value, {int decimals = 2}) {
  final formatted = (value * 100).toStringAsFixed(decimals);
  return '${value >= 0 ? '+' : ''}$formatted%';
}

/// Format a metric value based on its unit type.
///
/// Delegates to [formatCurrency] for monetary values, applies percentage
/// formatting for percentage units, and uses fixed decimals for ratios.
String formatMetricValue(double value, String? unitType, {int precision = 2}) {
  switch (unitType) {
    case 'percentage':
      return '${(value * 100).toStringAsFixed(precision)}%';
    case 'monetary':
      return formatCurrency(value);
    case 'ratio':
      return value.toStringAsFixed(precision);
    default:
      return value.toStringAsFixed(precision);
  }
}
