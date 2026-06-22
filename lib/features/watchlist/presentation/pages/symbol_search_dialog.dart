import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/symbol_search_provider.dart';

class SymbolSearchDialog extends StatefulWidget {
  final String watchlistId;

  const SymbolSearchDialog({super.key, required this.watchlistId});

  @override
  State<SymbolSearchDialog> createState() => _SymbolSearchDialogState();
}

class _SymbolSearchDialogState extends State<SymbolSearchDialog> {
  final _provider = SymbolSearchProvider();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppThemeColors.surface,
      title: Semantics(
        header: true,
        child: const Text(AppStrings.addSymbol, style: AppTypography.titleMedium),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Search for a stock symbol or company name',
              textField: true,
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Search symbol or name...',
                  prefixIcon: Icon(Icons.search, size: 16),
                ),
                autofocus: true,
                onChanged: (value) => _provider.search(value),
              ),
            ),
            const SizedBox(height: 8),
            _buildResults(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return SignalBuilder(builder: (_) {
      final results = _provider.searchResults.value;
      final isSearching = _provider.isSearching.value;
      final isAdding = _provider.isAdding.value;
      final error = _provider.searchError.value;

      if (isSearching || isAdding) {
        return const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (error != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(
            liveRegion: true,
            label: 'Error: $error',
            child: Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppThemeColors.bearish,
              ),
            ),
          ),
        );
      }

      if (results.isEmpty) {
        return const SizedBox(
          height: 40,
          child: Center(
            child: Text('Type to search...', style: AppTypography.bodySmall),
          ),
        );
      }

      return Semantics(
        label: '${results.length} search results found',
        child: SizedBox(
          height: 250,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              // A11Y: Add semantic label for each search result.
              return Semantics(
                button: true,
                label: 'Add ${result.symbol} - ${result.name} from ${result.exchange}',
                child: ListTile(
                  dense: true,
                  title: Text(
                    result.symbol,
                    style: AppTypography.monoSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${result.name} • ${result.exchange}',
                    style: AppTypography.monoTiny,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.add, size: 14),
                  onTap: () async {
                    final symbolId = await _provider.addToWatchlist(
                      widget.watchlistId,
                      result,
                    );
                    if (symbolId != null && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
