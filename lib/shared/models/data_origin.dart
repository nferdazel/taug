enum DataLatencyClass {
  realtime('REALTIME'),
  delayed('DELAYED'),
  eod('EOD'),
  derived('DERIVED'),
  syndicated('SYNDICATED'),
  unavailable('UNAVAILABLE');

  const DataLatencyClass(this.label);

  final String label;

  static DataLatencyClass fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'realtime':
        return DataLatencyClass.realtime;
      case 'delayed':
        return DataLatencyClass.delayed;
      case 'eod':
        return DataLatencyClass.eod;
      case 'derived':
        return DataLatencyClass.derived;
      case 'syndicated':
        return DataLatencyClass.syndicated;
      default:
        return DataLatencyClass.unavailable;
    }
  }
}

final class DataOrigin {
  final String sourceLabel;
  final DataLatencyClass latencyClass;
  final bool isOfficial;
  final bool isSynthetic;
  final DateTime? fetchedAt;
  final DateTime? asOf;

  const DataOrigin({
    required this.sourceLabel,
    required this.latencyClass,
    required this.isOfficial,
    required this.isSynthetic,
    this.fetchedAt,
    this.asOf,
  });

  factory DataOrigin.fromJson(
    Map<String, dynamic> json, {
    required String fallbackSourceLabel,
    required DataLatencyClass fallbackLatencyClass,
    required bool fallbackIsOfficial,
    bool fallbackIsSynthetic = false,
  }) {
    return DataOrigin(
      sourceLabel:
          json['source_label'] as String? ??
          json['source'] as String? ??
          fallbackSourceLabel,
      latencyClass: DataLatencyClass.fromValue(
        json['latency_class'] as String? ?? fallbackLatencyClass.name,
      ),
      isOfficial: json['is_official'] as bool? ?? fallbackIsOfficial,
      isSynthetic: json['is_synthetic'] as bool? ?? fallbackIsSynthetic,
      fetchedAt: _parseDateTime(json['fetched_at']),
      asOf: _parseDateTime(json['as_of'] ?? json['last_update']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
