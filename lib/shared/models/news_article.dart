import 'package:equatable/equatable.dart';

import 'data_origin.dart';

final class NewsArticle extends Equatable {
  final String id;
  final String? externalId;
  final String title;
  final String? summary;
  final String? content;
  final String url;
  final String source;
  final String? author;
  final DateTime publishedAt;
  final String? imageUrl;
  final List<String> categories;
  final List<int> symbols;
  final bool isBreaking;
  final int importance;
  final bool policyRelevant;
  final DataOrigin origin;

  const NewsArticle({
    required this.id,
    this.externalId,
    required this.title,
    this.summary,
    this.content,
    required this.url,
    required this.source,
    this.author,
    required this.publishedAt,
    this.imageUrl,
    this.categories = const [],
    this.symbols = const [],
    this.isBreaking = false,
    this.importance = 1,
    this.policyRelevant = false,
    required this.origin,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final Map<String, Object?> metadata =
        (json['metadata'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ) ??
        const <String, Object?>{};

    return NewsArticle(
      id: json['id'] as String,
      externalId: json['external_id'] as String?,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String,
      source: json['source'] as String,
      author: json['author'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      imageUrl: json['image_url'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      symbols:
          (json['symbols'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      isBreaking: json['is_breaking'] as bool? ?? false,
      importance: _readImportance(metadata),
      policyRelevant: metadata['policy_relevant'] as bool? ?? false,
      origin: DataOrigin.fromJson(
        json,
        fallbackSourceLabel: json['source'] as String? ?? 'RSS',
        fallbackLatencyClass: DataLatencyClass.syndicated,
        fallbackIsOfficial: false,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    externalId,
    title,
    summary,
    content,
    url,
    source,
    author,
    publishedAt,
    imageUrl,
    categories,
    symbols,
    isBreaking,
    importance,
    policyRelevant,
    origin,
  ];
}

int _readImportance(Map<String, Object?> metadata) {
  final Object? value = metadata['importance'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 1;
}
