import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../../shared/models/news_article.dart';
import '../../data/news_repository.dart';

class NewsProvider {
  final NewsRepository _repository;

  final articles = Signal<List<NewsArticle>>([]);
  final selectedCategory = Signal<String>('all');
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);

  NewsProvider({NewsRepository? repository})
    : _repository = repository ?? NewsRepository();

  Future<void> loadNews() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getNews(category: selectedCategory.value);

    if (result.isSuccess) {
      articles.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
  }

  Future<void> refreshNews() async {
    await _repository.refreshNews();
    await loadNews();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    loadNews();
  }
}
