import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../data/symbol_repository.dart';
import '../../data/watchlist_repository.dart';

class SymbolSearchProvider {
  final SymbolRepository _symbolRepository;
  final WatchlistRepository _watchlistRepository;

  final searchResults = Signal<List<SymbolSearchResult>>([]);
  final isSearching = Signal<bool>(false);
  final searchError = Signal<String?>(null);
  final isAdding = Signal<bool>(false);

  SymbolSearchProvider({
    SymbolRepository? symbolRepository,
    WatchlistRepository? watchlistRepository,
  }) : _symbolRepository = symbolRepository ?? SymbolRepository(),
       _watchlistRepository = watchlistRepository ?? WatchlistRepository();

  Future<void> search(String query) async {
    if (query.isEmpty) {
      searchResults.value = [];
      return;
    }

    isSearching.value = true;
    searchError.value = null;

    final localResult = await _symbolRepository.searchLocalSymbols(query);
    if (localResult.isSuccess && localResult.data!.isNotEmpty) {
      searchResults.value = localResult.data!;
      isSearching.value = false;
      return;
    }

    final result = await _symbolRepository.searchSymbols(query);

    if (result.isSuccess) {
      searchResults.value = result.data!;
    } else {
      searchError.value = ErrorSanitizer.message(result.error);
    }

    isSearching.value = false;
  }

  Future<int?> addToWatchlist(
    String watchlistId,
    SymbolSearchResult symbol,
  ) async {
    isAdding.value = true;
    searchError.value = null;

    try {
      final localResult = await _symbolRepository.searchLocalSymbols(
        symbol.symbol,
      );
      if (localResult.isSuccess && localResult.data!.isNotEmpty) {
        final symbolId = await _symbolRepository.getSymbolId(symbol.symbol);
        if (symbolId != null) {
          final itemsResult = await _watchlistRepository.getWatchlistItems(
            watchlistId,
          );
          if (itemsResult.isSuccess) {
            final alreadyExists = itemsResult.data!.any(
              (item) => item.ticker == symbol.symbol,
            );
            if (alreadyExists) {
              searchError.value = 'Already in watchlist';
              isAdding.value = false;
              return null;
            }
          }

          await _watchlistRepository.addToWatchlist(watchlistId, symbolId);
          isAdding.value = false;
          return symbolId;
        }
      }

      final insertedResult = await _symbolRepository.insertSymbol(symbol);
      if (insertedResult.isSuccess) {
        final symbolId = insertedResult.data!;
        await _watchlistRepository.addToWatchlist(watchlistId, symbolId);
        await _watchlistRepository.refreshQuoteSnapshots([symbol.symbol]);
        isAdding.value = false;
        return symbolId;
      }

      searchError.value = 'Failed to add symbol';
      isAdding.value = false;
      return null;
    } catch (e) {
      ErrorSanitizer.debugLog('SymbolSearchProvider', 'addToWatchlist error: $e');
      searchError.value = 'Failed to add symbol. Please try again.';
      isAdding.value = false;
      return null;
    }
  }

  void clearResults() {
    searchResults.value = [];
    searchError.value = null;
  }
}
