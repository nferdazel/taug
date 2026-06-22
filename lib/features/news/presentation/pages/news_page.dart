import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/models/news_article.dart';
import '../../../../shared/models/terminal_headline.dart';
import '../../../../shared/widgets/data_status_badge.dart';
import '../../data/news_intelligence_repository.dart';
import '../../data/news_repository.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _repository = NewsRepository();
  final _intelligenceRepository = NewsIntelligenceRepository();
  final _articles = Signal<List<NewsArticle>>([]);
  final _topHeadlines = Signal<List<TerminalHeadline>>([]);
  final _selectedCategory = Signal<String>('all');
  final _policyOnly = Signal<bool>(false);
  final _isLoading = Signal<bool>(false);
  final _isTopLoading = Signal<bool>(false);
  final _error = Signal<String?>(null);
  final _topError = Signal<String?>(null);
  final _lastUpdated = Signal<DateTime?>(null);

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _articles.dispose();
    _topHeadlines.dispose();
    _selectedCategory.dispose();
    _policyOnly.dispose();
    _isLoading.dispose();
    _isTopLoading.dispose();
    _error.dispose();
    _topError.dispose();
    _lastUpdated.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    await Future.wait([_loadNews(), _loadTopHeadlines()]);
  }

  Future<void> _loadNews() async {
    _isLoading.value = true;
    _error.value = null;

    final result = await _repository.getNews(
      category: _selectedCategory.value,
      policyRelevantOnly: _policyOnly.value,
    );

    if (result.isSuccess) {
      _articles.value = result.data!;
      _lastUpdated.value = DateTime.now();
    } else {
      _error.value = result.error.toString();
    }

    _isLoading.value = false;
  }

  Future<void> _loadTopHeadlines() async {
    _isTopLoading.value = true;
    _topError.value = null;

    final result = await _intelligenceRepository.getTopImpactHeadlines();

    if (result.isSuccess) {
      _topHeadlines.value = result.data!;
    } else {
      _topError.value = result.error.toString();
    }

    _isTopLoading.value = false;
  }

  Future<void> _refreshNews() async {
    await _repository.refreshNews();
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildTopImpactPanel(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildTopImpactPanel() {
    return SignalBuilder(builder: (_) {
      final headlines = _topHeadlines.value;
      final isLoading = _isTopLoading.value;

      if (isLoading && headlines.isEmpty) {
        return const SizedBox(height: 0);
      }

      if (headlines.isEmpty) {
        return const SizedBox(height: 0);
      }

      return RepaintBoundary(
        child: Container(
          height: 104,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppThemeColors.border)),
          ),
          child: Column(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppThemeColors.backgroundLight,
                  border: Border(
                    bottom: BorderSide(color: AppThemeColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Semantics(
                      header: true,
                      child: const Text('TOP IMPACT', style: AppTypography.monoSection),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const DataStatusBadge(origin: _topImpactOrigin),
                    const Spacer(),
                    if (_topError.value != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          'Ranking degraded',
                          style: AppTypography.monoTiny.copyWith(
                            color: AppThemeColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: headlines.length > 4 ? 4 : headlines.length,
                  itemExtent: 26,
                  itemBuilder: (context, index) {
                    final headline = headlines[index];
                    return Semantics(
                      button: true,
                      label: '${headline.tag}: ${headline.title}',
                      child: InkWell(
                        onTap: () => _launchUrl(headline.url),
                        focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppThemeColors.border,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 112,
                                child: Text(
                                  headline.tag,
                                  style: AppTypography.monoTiny.copyWith(
                                    color: _importanceColor(headline.importance),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Text(
                                  headline.title,
                                  style: AppTypography.monoTiny.copyWith(
                                    color: AppThemeColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              SizedBox(
                                width: 92,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (headline.isBreaking) ...[
                                      Text(
                                        'B',
                                        style: AppTypography.monoTiny.copyWith(
                                          color: AppThemeColors.bearish,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      _formatTime(headline.publishedAt),
                                      style: AppTypography.monoTiny.copyWith(
                                        color: AppThemeColors.textTertiary,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildCategoryFilter(),
          const SizedBox(width: AppSpacing.lg),
          _buildPolicyToggle(),
          const SizedBox(width: AppSpacing.lg),
          const DataStatusBadge(origin: _newsOrigin),
          const Spacer(),
          if (_lastUpdated.value != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(
                'Updated ${_formatTime(_lastUpdated.value!)}',
                style: AppTypography.monoTiny.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
            ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SignalBuilder(builder: (_) {
      final categories = [
        'all',
        'markets',
        'economy',
        'geopolitics',
        'earnings',
        'policy',
      ];
      final current = _selectedCategory.value;

      return Row(
        children: categories.map((cat) {
          final isSelected = current == cat;
          final displayLabel = cat == 'all'
              ? AppStrings.all
              : cat[0].toUpperCase() + cat.substring(1);
          // A11Y: Add Semantics with button + selected state for category filters.
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '$displayLabel news filter',
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                child: TextButton(
                  onPressed: () {
                    _selectedCategory.value = cat;
                    _loadNews();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppThemeColors.accent
                        : AppThemeColors.backgroundLight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    displayLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AppThemeColors.textPrimary
                          : AppThemeColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // A11Y: Add Semantics with button + selected state for policy toggle.
  Widget _buildPolicyToggle() {
    return SignalBuilder(builder: (_) {
      final selected = _policyOnly.value;
      return Semantics(
        button: true,
        selected: selected,
        label: 'Policy Lens news filter',
        child: SizedBox(
          height: AppSpacing.buttonHeight,
          child: TextButton(
            onPressed: () {
              _policyOnly.value = !selected;
              _loadNews();
            },
            style: TextButton.styleFrom(
              backgroundColor: selected
                  ? AppThemeColors.warning
                  : AppThemeColors.backgroundLight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Policy Lens',
              style: AppTypography.bodySmall.copyWith(
                color: selected
                    ? AppThemeColors.textPrimary
                    : AppThemeColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRefreshButton() {
    return SignalBuilder(builder: (_) {
      final isLoading = _isLoading.value;
      return SizedBox(
        height: AppSpacing.buttonHeight,
        width: AppSpacing.buttonHeight,
        child: Semantics(
          label: isLoading ? 'Refreshing news' : 'Refresh news',
          button: true,
          child: IconButton(
            onPressed: isLoading ? null : _refreshNews,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : const Icon(Icons.refresh, size: 16),
            padding: EdgeInsets.zero,
          ),
        ),
      );
    });
  }

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      final articles = _articles.value;
      final isLoading = _isLoading.value;
      final error = _error.value;

      if (isLoading && articles.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && articles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 32,
                color: AppThemeColors.bearish,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadNews,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        );
      }

      if (articles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.newspaper_outlined,
                size: 32,
                color: AppThemeColors.textTertiary,
              ),
              const SizedBox(height: 8),
              const Text('No news articles', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshNews,
                child: const Text('Fetch News'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshNews,
        child: ListView.builder(
          itemCount: articles.length,
          itemExtent: 80,
          itemBuilder: (context, index) => _buildNewsItem(articles[index]),
        ),
      );
    });
  }

  Widget _buildNewsItem(NewsArticle article) {
    // A11Y: Build semantic label for news article.
    final String semanticLabel = '${article.source}: ${article.title}'
        '${article.isBreaking ? ', breaking' : ''}';

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(
          onTap: () => _launchUrl(article.url),
          focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
          child: Container(
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
          ),
        ),
      ),
    );
  }

  Color _importanceColor(int importance) {
    return switch (importance) {
      3 => AppThemeColors.bearish,
      2 => AppThemeColors.warning,
      _ => AppThemeColors.accent,
    };
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
    } catch (e) {
      debugPrint('[News] launchUrl error: $e');
    }
  }
}

const DataOrigin _newsOrigin = DataOrigin(
  sourceLabel: 'RSS Feeds',
  latencyClass: DataLatencyClass.syndicated,
  isOfficial: false,
  isSynthetic: false,
);

const DataOrigin _topImpactOrigin = DataOrigin(
  sourceLabel: 'Ranked Feed',
  latencyClass: DataLatencyClass.derived,
  isOfficial: false,
  isSynthetic: false,
);
