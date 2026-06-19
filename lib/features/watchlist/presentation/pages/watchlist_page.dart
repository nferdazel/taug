import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/price_cell.dart';
import '../providers/watchlist_provider.dart';

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
          border: Border(
            bottom: BorderSide(color: AppThemeColors.border),
          ),
        ),
        child: Row(
          children: [
            _buildWatchlistSelector(),
            const Spacer(),
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
            .map((w) => DropdownMenuItem(
                  value: w.id,
                  child: Text(w.name),
                ))
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
        onPressed: _showAddWatchlistDialog,
        icon: const Icon(Icons.add, size: 12),
        label: const Text('New'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      height: 24,
      width: 24,
      child: IconButton(
        onPressed: () => _provider.loadPrices(),
        icon: const Icon(Icons.refresh, size: 14),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContent() {
    return Watch((_) {
      final items = _provider.watchlistItems.value;
      final isLoading = _provider.isLoading.value;

      if (isLoading && items.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt,
                size: 32,
                color: AppThemeColors.textTertiary,
              ),
              const SizedBox(height: 8),
              Text(
                'No items in watchlist',
                style: AppTypography.bodySmall,
              ),
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

  Widget _buildPriceTable(List items) {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemExtent: 28,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildTableRow(item);
            },
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
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Symbol', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Name', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Price', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Change', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text('Vol', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildTableRow(dynamic item) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${item.sortOrder + 1}',
              style: AppTypography.monoTiny,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.ticker ?? '',
              style: AppTypography.monoSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.name ?? '',
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: PriceCell(
              value: '0.00',
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: PriceCell(
              value: '0.00',
              change: 0,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '0',
              style: AppTypography.monoTiny,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 28,
            child: IconButton(
              onPressed: () => _provider.removeFromWatchlist(item.id),
              icon: const Icon(Icons.close, size: 12),
              padding: EdgeInsets.zero,
              color: AppThemeColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWatchlistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeColors.surface,
        title: const Text('New Watchlist', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Watchlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _provider.createWatchlist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showAddSymbolDialog() {
    // TODO: Implement symbol search and add
  }
}
