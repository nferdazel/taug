import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../../shared/models/news_article.dart';

class NewsRepository {
  final SupabaseClient _client;

  NewsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<NewsArticle>>> getNews({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('${AppSchema.name}.${AppSchema.newsArticles}')
          .select();

      if (category != null && category != 'all') {
        query = query.contains('categories', '{$category}');
      }

      final response = await query
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);

      final articles = response
          .map((json) => NewsArticle.fromJson(json))
          .toList();

      return Result.success(articles);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  Future<Result<void>> refreshNews() async {
    try {
      await _client.functions.invoke('refresh-news');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
