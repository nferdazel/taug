import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/watchlist_entity.dart';
import '../providers/watchlist_provider.dart';
import 'symbol_search_dialog.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final _provider = WatchlistProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadWatchlists();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
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
    return Watch((_) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            _buildWatchlistSelector(),
            const Spacer(),
            if (_provider.lastUpdated.value != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatLastUpdated(_provider.lastUpdated.value!),
                  style: AppTypography.monoTiny.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
              ),
            _buildAddButton(),
            const SizedBox(width: 4),
            _buildRefreshButton(),
          ],
        ),
      );
    });
  }

  Widget _buildWatchlistSelector() {
    return Watch((_) {
      final watchlists = _provider.watchlists.value;
      final current = _provider.currentWatchlist.value;

      return DropdownButton<String>(
        value: current?.id,
        underline: const SizedBox(),
        dropdownColor: AppThemeColors.surface,
        style: AppTypography.labelMedium,
        isDense: true,
        items: watchlists
            .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
            .toList(),
        onChanged: (id) {
          if (id != null) {
            final watchlist = watchlists.firstWhere((w) => w.id == id);
            _provider.selectWatchlist(watchlist);
          }
        },
      );
    });
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 24,
      child: TextButton.icon(
        onPressed: _showAddSymbolDialog,
        icon: const Icon(Icons.add, size: 12),
        label: const Text('Add'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Watch((_) {
      final isLoading = _provider.isLoading.value;
      return SizedBox(
        height: 24,
        width: 24,
        child: IconButton(
          onPressed: isLoading ? null : () => _provider.loadPrices(),
          icon: isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : const Icon(Icons.refresh, size: 14),
          padding: EdgeInsets.zero,
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final items = _provider.watchlistItems.value;
      final isLoading = _provider.isLoading.value;
      final error = _provider.error.value;

      if (isLoading && items.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 32, color: AppThemeColors.bearish),
              const SizedBox(height: 8),
              Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _provider.loadWatchlists(),
                  child: const Text(AppStrings.retry),
                ),
              ),
            ],
          ),
        );
      }

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.list_alt, size: 32, color: AppThemeColors.textTertiary),
              const SizedBox(height: 8),
              const Text('No items in watchlist', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  onPressed: _showAddSymbolDialog,
                  icon: const Icon(Icons.add, size: 12),
                  label: const Text(AppStrings.addSymbol),
                ),
              ),
            ],
          ),
        );
      }

      return _buildPriceTable(items);
    });
  }

  Widget _buildPriceTable(List<WatchlistItem> items) {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _provider.loadPrices(),
            child: ListView.builder(
              itemCount: items.length,
              itemExtent: 32,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildTableRow(item, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: AppThemeColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Symbol', style: AppTypography.sectionHeader)),
          Expanded(flex: 3, child: Text('Name', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Price', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Change', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text('Vol', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildTableRow(WatchlistItem item, int index) {
    return Watch((_) {
      final price = _provider.getPriceForSymbol(item.ticker ?? '');

      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('${index + 1}', style: AppTypography.monoTiny),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.ticker ?? '',
                style: AppTypography.monoSmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item.name ?? '',
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                price != null ? _formatPrice(price.price, item.assetClass) : '-',
                style: AppTypography.monoSmall,
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: price != null
                  ? Text(
                      price.changePercent >= 0
                          ? '+${price.changePercent.toStringAsFixed(2)}%'
                          : '${price.changePercent.toStringAsFixed(2)}%',
                      style: AppTypography.monoSmall.copyWith(
                        color: price.changePercent >= 0
                            ? AppThemeColors.bullish
                            : AppThemeColors.bearish,
                      ),
                      textAlign: TextAlign.right,
                    )
                  : const Text('-', style: AppTypography.monoSmall, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 1,
              child: Text(
                price != null ? _formatVolume(price.volume) : '-',
                style: AppTypography.monoTiny,
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 28,
              child: IconButton(
                onPressed: () => _showDeleteConfirmation(item),
                icon: const Icon(Icons.close, size: 12),
                padding: EdgeInsets.zero,
                color: AppThemeColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatPrice(double price, String? assetClass) {
    if (assetClass == 'crypto') {
      if (price >= 1000) return price.toStringAsFixed(2);
      if (price >= 1) return price.toStringAsFixed(4);
      return price.toStringAsFixed(6);
    }
    if (price >= 10000) return price.toStringAsFixed(0);
    return price.toStringAsFixed(2);
  }

  String _formatVolume(int volume) => formatVolume(volume);

  String _formatLastUpdated(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 5) return 'Live';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showAddSymbolDialog() {
    final currentWatchlist = _provider.currentWatchlist.value;
    if (currentWatchlist == null) return;

    showDialog(
      context: context,
      builder: (context) => SymbolSearchDialog(watchlistId: currentWatchlist.id),
    ).then((_) {
      if (_provider.currentWatchlist.value != null) {
        _provider.loadWatchlistItems(_provider.currentWatchlist.value!.id);
      }
    });
  }

  void _showDeleteConfirmation(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeColors.surface,
        title: const Text('Remove Symbol', style: AppTypography.titleMedium),
        content: Text(
          'Remove ${item.ticker} from watchlist?',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _provider.removeFromWatchlist(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.bearish),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
