import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/news_article.dart';
import '../../data/news_repository.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _repository = NewsRepository();
  final _articles = Signal<List<NewsArticle>>([]);
  final _selectedCategory = Signal<String>('all');
  final _isLoading = Signal<bool>(false);
  final _error = Signal<String?>(null);
  final _lastUpdated = Signal<DateTime?>(null);

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    _isLoading.value = true;
    _error.value = null;

    final result = await _repository.getNews(
      category: _selectedCategory.value,
    );

    if (result.isSuccess) {
      _articles.value = result.data!;
      _lastUpdated.value = DateTime.now();
    } else {
      _error.value = result.error.toString();
    }

    _isLoading.value = false;
  }

  Future<void> _refreshNews() async {
    await _repository.refreshNews();
    await _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildCategoryFilter(),
          const Spacer(),
          if (_lastUpdated.value != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Updated ${_formatTime(_lastUpdated.value!)}',
                style: AppTypography.monoTiny.copyWith(color: AppThemeColors.textTertiary),
              ),
            ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Watch((_) {
      final categories = ['all', 'markets', 'economy', 'geopolitics', 'earnings'];
      final current = _selectedCategory.value;

      return Row(
        children: categories.map((cat) {
          final isSelected = current == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              height: 24,
              child: TextButton(
                onPressed: () {
                  _selectedCategory.value = cat;
                  _loadNews();
                },
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppThemeColors.accent
                      : AppThemeColors.backgroundLight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  cat == 'all' ? AppStrings.all : cat[0].toUpperCase() + cat.substring(1),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppThemeColors.textPrimary
                        : AppThemeColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildRefreshButton() {
    return Watch((_) {
      final isLoading = _isLoading.value;
      return SizedBox(
        height: 24,
        width: 24,
        child: IconButton(
          onPressed: isLoading ? null : _refreshNews,
          icon: isLoading
              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
              : const Icon(Icons.refresh, size: 14),
          padding: EdgeInsets.zero,
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final articles = _articles.value;
      final isLoading = _isLoading.value;
      final error = _error.value;

      if (isLoading && articles.isEmpty) {
        return const Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      if (error != null && articles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 32, color: AppThemeColors.bearish),
              const SizedBox(height: 8),
              Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadNews, child: const Text(AppStrings.retry)),
            ],
          ),
        );
      }

      if (articles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.newspaper_outlined, size: 32, color: AppThemeColors.textTertiary),
              const SizedBox(height: 8),
              const Text('No news articles', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _refreshNews, child: const Text('Fetch News')),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshNews,
        child: ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) => _buildNewsItem(articles[index]),
        ),
      );
    });
  }

  Widget _buildNewsItem(NewsArticle article) {
    return InkWell(
      onTap: () => _launchUrl(article.url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (article.isBreaking) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppThemeColors.bearish,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'BREAKING',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppThemeColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  article.source.toUpperCase(),
                  style: AppTypography.monoTiny.copyWith(color: AppThemeColors.textTertiary),
                ),
                const Spacer(),
                Text(
                  _formatTime(article.publishedAt),
                  style: AppTypography.monoTiny.copyWith(color: AppThemeColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              article.title,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (article.summary != null && article.summary!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                article.summary!,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (article.categories.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: article.categories.take(3).map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppThemeColors.backgroundLight,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: AppThemeColors.border),
                    ),
                    child: Text(
                      cat.toUpperCase(),
                      style: AppTypography.monoTiny.copyWith(color: AppThemeColors.textSecondary),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
