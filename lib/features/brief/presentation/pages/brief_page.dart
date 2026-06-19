import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/models/econ_event.dart';
import '../../../../shared/models/price_data.dart';
import '../../../../shared/models/terminal_headline.dart';
import '../../../../shared/widgets/data_status_badge.dart';
import '../../data/brief_repository.dart';
import '../../domain/brief_snapshot.dart';

class BriefPage extends StatefulWidget {
  const BriefPage({super.key});

  @override
  State<BriefPage> createState() => _BriefPageState();
}

class _BriefPageState extends State<BriefPage> {
  final BriefRepository _repository = BriefRepository();
  final Signal<BriefSnapshot?> _snapshot = Signal<BriefSnapshot?>(null);
  final Signal<bool> _isLoading = Signal<bool>(false);
  final Signal<String?> _error = Signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadBrief();
  }

  Future<void> _loadBrief() async {
    _isLoading.value = true;
    _error.value = null;

    final Result<BriefSnapshot> result = await _repository.getBriefSnapshot();
    if (result.isSuccess) {
      _snapshot.value = result.data!;
    } else {
      _error.value = result.error.toString();
    }

    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Watch((_) {
      final BriefSnapshot? snapshot = _snapshot.value;
      final bool isLoading = _isLoading.value;

      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: <Widget>[
            const Text('TERMINAL BRIEF', style: AppTypography.monoSection),
            const SizedBox(width: AppSpacing.lg),
            const DataStatusBadge(origin: _briefOrigin),
            const Spacer(),
            if (snapshot != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Text(
                  'Updated ${DateFormat('HH:mm:ss').format(snapshot.fetchedAt)}',
                  style: AppTypography.monoTiny.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
              ),
            SizedBox(
              width: 24,
              height: AppSpacing.buttonHeight,
              child: IconButton(
                onPressed: isLoading ? null : _loadBrief,
                padding: EdgeInsets.zero,
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.refresh, size: 16),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final BriefSnapshot? snapshot = _snapshot.value;
      final bool isLoading = _isLoading.value;
      final String? error = _error.value;

      if (isLoading && snapshot == null) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && snapshot == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: AppThemeColors.bearish,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        );
      }

      if (snapshot == null) {
        return const SizedBox.shrink();
      }

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 980) {
            return _buildMobileBrief(snapshot);
          }
          return _buildDesktopBrief(snapshot);
        },
      );
    });
  }

  Widget _buildDesktopBrief(BriefSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: _buildPanel(
              title: 'TOP IMPACT',
              subtitle: '${snapshot.headlines.length} ranked headlines',
              child: _buildHeadlineList(snapshot.headlines),
            ),
          ),
          const SizedBox(width: AppSpacing.sectionGap),
          Expanded(
            flex: 3,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: _buildPanel(
                    title: 'MARKET MOVERS',
                    subtitle: '${snapshot.movers.length} active names',
                    child: _buildMoversList(snapshot.movers),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildPanel(
                    title: 'MACRO CALENDAR',
                    subtitle: 'US events importance >= 2',
                    child: _buildMacroList(snapshot.macroEvents),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrief(BriefSnapshot snapshot) {
    return RefreshIndicator(
      onRefresh: _loadBrief,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        children: <Widget>[
          SizedBox(
            height: 248,
            child: _buildPanel(
              title: 'TOP IMPACT',
              subtitle: '${snapshot.headlines.length} ranked headlines',
              child: _buildHeadlineList(snapshot.headlines),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SizedBox(
            height: 224,
            child: _buildPanel(
              title: 'MARKET MOVERS',
              subtitle: '${snapshot.movers.length} active names',
              child: _buildMoversList(snapshot.movers),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SizedBox(
            height: 224,
            child: _buildPanel(
              title: 'MACRO CALENDAR',
              subtitle: 'US events importance >= 2',
              child: _buildMacroList(snapshot.macroEvents),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: AppThemeColors.backgroundLight,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Text(title, style: AppTypography.monoSection),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: AppTypography.monoTiny.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildHeadlineList(List<TerminalHeadline> headlines) {
    if (headlines.isEmpty) {
      return _buildEmptyState('No impact headlines');
    }

    return ListView.builder(
      itemCount: headlines.length,
      itemExtent: 46,
      itemBuilder: (BuildContext context, int index) {
        final TerminalHeadline headline = headlines[index];
        return RepaintBoundary(
          child: InkWell(
            onTap: () => _launchUrl(headline.url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 84,
                    child: Text(
                      headline.tag,
                      style: AppTypography.monoTiny.copyWith(
                        color: _importanceColor(headline.importance),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          headline.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppThemeColors.textPrimary,
                          ),
                        ),
                        Text(
                          headline.sourceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.monoTiny.copyWith(
                            color: AppThemeColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      _formatTime(headline.publishedAt),
                      textAlign: TextAlign.right,
                      style: AppTypography.monoTiny.copyWith(
                        color: AppThemeColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoversList(List<PriceData> movers) {
    if (movers.isEmpty) {
      return _buildEmptyState('No movers available');
    }

    return ListView.builder(
      itemCount: movers.length,
      itemExtent: 30,
      itemBuilder: (BuildContext context, int index) {
        final PriceData item = movers[index];
        final bool positive = item.changePercent >= 0;
        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 58,
                  child: Text(
                    item.symbol,
                    style: AppTypography.monoLabel.copyWith(
                      color: AppThemeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.price.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: AppTypography.monoTiny.copyWith(
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  child: Text(
                    '${positive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                    textAlign: TextAlign.right,
                    style: AppTypography.monoTiny.copyWith(
                      color: positive
                          ? AppThemeColors.bullish
                          : AppThemeColors.bearish,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroList(List<EconEvent> events) {
    if (events.isEmpty) {
      return _buildEmptyState('Official macro feed pending');
    }

    return ListView.builder(
      itemCount: events.length,
      itemExtent: 36,
      itemBuilder: (BuildContext context, int index) {
        final EconEvent event = events[index];
        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
                  child: Text(
                    '${event.importance}',
                    style: AppTypography.monoTiny.copyWith(
                      color: _importanceColor(event.importance),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppThemeColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${event.country} ${event.eventTime ?? 'TBD'}',
                        style: AppTypography.monoTiny.copyWith(
                          color: AppThemeColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String label) {
    return Center(
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppThemeColors.textTertiary,
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
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    return DateFormat('MMM d').format(time);
  }

  Future<void> _launchUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

const DataOrigin _briefOrigin = DataOrigin(
  sourceLabel: 'Composite',
  latencyClass: DataLatencyClass.derived,
  isOfficial: false,
  isSynthetic: false,
);
