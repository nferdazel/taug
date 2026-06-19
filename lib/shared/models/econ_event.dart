import 'package:equatable/equatable.dart';

import 'data_origin.dart';

final class EconEvent extends Equatable {
  final String id;
  final String title;
  final String country;
  final String category;
  final int importance;
  final double? actual;
  final double? forecast;
  final double? previous;
  final String? unit;
  final DateTime eventDate;
  final String? eventTime;
  final String source;
  final DataOrigin origin;

  const EconEvent({
    required this.id,
    required this.title,
    required this.country,
    required this.category,
    required this.importance,
    this.actual,
    this.forecast,
    this.previous,
    this.unit,
    required this.eventDate,
    this.eventTime,
    this.source = 'manual',
    required this.origin,
  });

  factory EconEvent.fromJson(Map<String, dynamic> json) {
    return EconEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      country: json['country'] as String,
      category: json['category'] as String,
      importance: json['importance'] as int,
      actual: (json['actual'] as num?)?.toDouble(),
      forecast: (json['forecast'] as num?)?.toDouble(),
      previous: (json['previous'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventTime: json['event_time'] as String?,
      source: json['source'] as String? ?? 'manual',
      origin: DataOrigin.fromJson(
        json,
        fallbackSourceLabel: json['source'] as String? ?? 'manual',
        fallbackLatencyClass: DataLatencyClass.derived,
        fallbackIsOfficial: false,
        fallbackIsSynthetic: json['source'] == 'manual',
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    country,
    category,
    importance,
    actual,
    forecast,
    previous,
    unit,
    eventDate,
    eventTime,
    source,
    origin,
  ];
}
