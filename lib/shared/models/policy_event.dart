import 'package:equatable/equatable.dart';

import 'data_origin.dart';

final class PolicyEvent extends Equatable {
  final String id;
  final String externalId;
  final String title;
  final String? summary;
  final String url;
  final String source;
  final String sourceLabel;
  final String country;
  final String agency;
  final String category;
  final int importance;
  final DateTime publishedAt;
  final Map<String, Object?> metadata;
  final DataOrigin origin;

  const PolicyEvent({
    required this.id,
    required this.externalId,
    required this.title,
    this.summary,
    required this.url,
    required this.source,
    required this.sourceLabel,
    required this.country,
    required this.agency,
    required this.category,
    required this.importance,
    required this.publishedAt,
    required this.metadata,
    required this.origin,
  });

  factory PolicyEvent.fromJson(Map<String, dynamic> json) {
    return PolicyEvent(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      url: json['url'] as String,
      source: json['source'] as String,
      sourceLabel: json['source_label'] as String? ?? json['source'] as String,
      country: json['country'] as String? ?? 'US',
      agency: json['agency'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'policy',
      importance: json['importance'] as int? ?? 1,
      publishedAt: DateTime.parse(json['published_at'] as String),
      metadata:
          (json['metadata'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, Object?>{},
      origin: DataOrigin.fromJson(
        json,
        fallbackSourceLabel: json['source_label'] as String? ?? 'Official',
        fallbackLatencyClass: DataLatencyClass.syndicated,
        fallbackIsOfficial: json['is_official'] as bool? ?? true,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    externalId,
    title,
    summary,
    url,
    source,
    sourceLabel,
    country,
    agency,
    category,
    importance,
    publishedAt,
    metadata,
    origin,
  ];
}
