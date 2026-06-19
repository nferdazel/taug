import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/news_article.dart';
import '../providers/news_provider.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _provider = NewsProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadNews();
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
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border),
        ),
      ),
      child: Row(
        children: [
          _buildCategoryFilter(),
          const Spacer(),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Watch((_) {
      final categories = ['all', 'markets', 'economy', 'geopolitics'];
      final current = _provider.selectedCategory.value;

      return Row(
        children: categories.map((cat) {
          final isSelected = current == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              height: 24,
              child: TextButton(
                onPressed: () => _provider.selectCategory(cat),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppThemeColors.accent
                      : AppThemeColors.backgroundLight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  cat == 'all'
                      ? AppStrings.all
                      : cat[0].toUpperCase() + cat.substring(1),
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
    return SizedBox(
      height: 24,
      width: 24,
      child: IconButton(
        onPressed: () => _provider.refreshNews(),
        icon: const Icon(Icons.refresh, size: 14),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContent() {
    return Watch((_) {
      final articles = _provider.articles.value;
      final isLoading = _provider.isLoading.value;

      if (isLoading && articles.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (articles.isEmpty) {
        return const Center(
          child: Text(
            AppStrings.noData,
            style: AppTypography.bodySmall,
          ),
        );
      }

      return ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildNewsItem(article);
        },
      );
    });
  }

  Widget _buildNewsItem(NewsArticle article) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (article.isBreaking) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.bearish,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'BREAKING',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                article.source.toUpperCase(),
                style: AppTypography.monoTiny.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(article.publishedAt),
                style: AppTypography.monoTiny.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            article.title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (article.summary != null) ...[
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.backgroundLight,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppThemeColors.border),
                  ),
                  child: Text(
                    cat.toUpperCase(),
                    style: AppTypography.monoTiny.copyWith(
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }
}
