import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/news_article.dart';

class NewsAlertService {
  final SupabaseClient _client;

  NewsAlertService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<NewsArticle>>> getBreakingNews() async {
    try {
      final response = await _client
          .from(AppSchema.newsArticles)
          .select()
          .eq('is_breaking', true)
          .order('published_at', ascending: false)
          .limit(10);

      final articles = response
          .map((json) => NewsArticle.fromJson(json))
          .toList();

      return Result.success(articles);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<int>> getUnreadCount() async {
    try {
      final response = await _client
          .from(AppSchema.newsArticles)
          .select('id')
          .eq('is_breaking', true)
          .gt(
            'published_at',
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          );

      return Result.success(response.length);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
