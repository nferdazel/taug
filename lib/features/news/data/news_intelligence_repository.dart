import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/terminal_headline.dart';

class NewsIntelligenceRepository {
  final SupabaseClient _client;

  NewsIntelligenceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<TerminalHeadline>>> getTopImpactHeadlines({
    int newsLimit = 80,
    int policyLimit = 40,
    int resultLimit = 6,
  }) async {
    try {
      final List<dynamic> newsRows = await _client
          .from(AppSchema.newsArticles)
          .select()
          .order('published_at', ascending: false)
          .limit(newsLimit);

      final List<dynamic> policyRows = await _client
          .from(AppSchema.policyEvents)
          .select()
          .gte('importance', 2)
          .order('published_at', ascending: false)
          .limit(policyLimit);

      final _RankPayload payload = _RankPayload(
        newsRows: newsRows
            .map((dynamic row) => Map<String, Object?>.from(row as Map))
            .toList(),
        policyRows: policyRows
            .map((dynamic row) => Map<String, Object?>.from(row as Map))
            .toList(),
        resultLimit: resultLimit,
      );

      final List<Map<String, Object?>> ranked = await compute(
        _rankHeadlines,
        payload,
      );

      final List<TerminalHeadline> headlines = ranked
          .map(TerminalHeadlineMapper.fromMap)
          .toList();
      return Result.success(headlines);
    } catch (e) {
      debugPrint('[NewsIntelligenceRepo] getTopImpactHeadlines: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}

class TerminalHeadlineMapper {
  static TerminalHeadline fromMap(Map<String, Object?> json) {
    return TerminalHeadline(
      kind: json['kind'] == 'policy'
          ? TerminalHeadlineKind.policy
          : TerminalHeadlineKind.news,
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      url: json['url'] as String,
      sourceLabel: json['source_label'] as String,
      tag: json['tag'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      importance: json['importance'] as int,
      impactScore: (json['impact_score'] as num).toDouble(),
      isBreaking: json['is_breaking'] as bool? ?? false,
      isOfficial: json['is_official'] as bool? ?? false,
    );
  }
}

class _RankPayload {
  final List<Map<String, Object?>> newsRows;
  final List<Map<String, Object?>> policyRows;
  final int resultLimit;

  const _RankPayload({
    required this.newsRows,
    required this.policyRows,
    required this.resultLimit,
  });
}

List<Map<String, Object?>> _rankHeadlines(_RankPayload payload) {
  final DateTime now = DateTime.now().toUtc();
  final List<Map<String, Object?>> combined = <Map<String, Object?>>[];

  for (final Map<String, Object?> row in payload.newsRows) {
    combined.add(_mapNewsRow(row, now));
  }
  for (final Map<String, Object?> row in payload.policyRows) {
    combined.add(_mapPolicyRow(row, now));
  }

  combined.sort((Map<String, Object?> a, Map<String, Object?> b) {
    final double aScore = (a['impact_score'] as num).toDouble();
    final double bScore = (b['impact_score'] as num).toDouble();
    return bScore.compareTo(aScore);
  });

  return combined.take(payload.resultLimit).toList();
}

Map<String, Object?> _mapNewsRow(Map<String, Object?> row, DateTime now) {
  final Map<String, Object?> metadata = _extractObjectMap(row['metadata']);
  final List<String> categories = _extractStringList(row['categories']);
  final DateTime publishedAt = DateTime.parse(row['published_at'] as String);
  final int importance = _readImportance(metadata);
  final bool isBreaking = row['is_breaking'] as bool? ?? false;
  final bool policyRelevant = metadata['policy_relevant'] as bool? ?? false;
  final bool isOfficial = row['is_official'] as bool? ?? false;

  double score = importance * 30;
  score += _recencyScore(now, publishedAt);
  score += isBreaking ? 20 : 0;
  score += policyRelevant ? 14 : 0;
  score += isOfficial ? 6 : 0;
  score += categories.contains('markets') ? 8 : 0;
  score += categories.contains('economy') ? 7 : 0;
  score += categories.contains('geopolitics') ? 6 : 0;

  return <String, Object?>{
    'kind': 'news',
    'id': row['id'] as String,
    'title': row['title'] as String? ?? '',
    'summary': row['summary'] as String?,
    'url': row['url'] as String,
    'source_label':
        row['source_label'] as String? ?? row['source'] as String? ?? 'News',
    'tag': _newsTag(categories),
    'published_at': publishedAt.toIso8601String(),
    'importance': importance,
    'impact_score': score,
    'is_breaking': isBreaking,
    'is_official': isOfficial,
  };
}

Map<String, Object?> _mapPolicyRow(Map<String, Object?> row, DateTime now) {
  final String agency = row['agency'] as String? ?? 'Policy';
  final DateTime publishedAt = DateTime.parse(row['published_at'] as String);
  final int importance = row['importance'] as int? ?? 1;
  final bool isOfficial = row['is_official'] as bool? ?? true;

  double score = 40 + (importance * 32);
  score += _recencyScore(now, publishedAt);
  score += isOfficial ? 10 : 0;
  score += _policyCategoryBonus(row['category'] as String? ?? 'policy');

  return <String, Object?>{
    'kind': 'policy',
    'id': row['id'] as String,
    'title': row['title'] as String? ?? '',
    'summary': row['summary'] as String?,
    'url': row['url'] as String,
    'source_label': row['source_label'] as String? ?? agency,
    'tag': agency.toUpperCase(),
    'published_at': publishedAt.toIso8601String(),
    'importance': importance,
    'impact_score': score,
    'is_breaking': importance >= 3,
    'is_official': isOfficial,
  };
}

Map<String, Object?> _extractObjectMap(Object? value) {
  if (value is Map) {
    return value.map(
      (Object? key, Object? innerValue) => MapEntry(key.toString(), innerValue),
    );
  }
  return const <String, Object?>{};
}

List<String> _extractStringList(Object? value) {
  if (value is List) {
    return value.map((Object? item) => item.toString()).toList();
  }
  return const <String>[];
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

double _recencyScore(DateTime now, DateTime publishedAt) {
  final int ageMinutes = now.difference(publishedAt.toUtc()).inMinutes;
  if (ageMinutes <= 15) {
    return 32;
  }
  if (ageMinutes <= 60) {
    return 24;
  }
  if (ageMinutes <= 180) {
    return 18;
  }
  if (ageMinutes <= 720) {
    return 10;
  }
  if (ageMinutes <= 1440) {
    return 6;
  }
  return 2;
}

double _policyCategoryBonus(String category) {
  switch (category) {
    case 'monetary_policy':
      return 18;
    case 'market_regulation':
      return 16;
    case 'fiscal_policy':
      return 14;
    case 'enforcement':
      return 12;
    case 'executive_action':
      return 10;
    default:
      return 6;
  }
}

String _newsTag(List<String> categories) {
  if (categories.contains('policy')) {
    return 'POLICY';
  }
  if (categories.contains('markets')) {
    return 'MARKETS';
  }
  if (categories.contains('economy')) {
    return 'ECON';
  }
  if (categories.contains('geopolitics')) {
    return 'GEO';
  }
  if (categories.contains('earnings')) {
    return 'ERNS';
  }
  return 'NEWS';
}
