import 'package:signals/signals.dart';
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
  })  : _symbolRepository = symbolRepository ?? SymbolRepository(),
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
      searchError.value = result.error.toString();
    }

    isSearching.value = false;
  }

  Future<void> addToWatchlist(String watchlistId, SymbolSearchResult symbol) async {
    isAdding.value = true;

    try {
      final symbolResponse = await _symbolRepository.searchLocalSymbols(symbol.symbol);
      if (symbolResponse.isSuccess && symbolResponse.data!.isNotEmpty) {
        final itemsResult = await _watchlistRepository.getWatchlistItems(watchlistId);
        if (itemsResult.isSuccess) {
          final alreadyExists = itemsResult.data!.any(
            (item) => item.ticker == symbol.symbol,
          );
          if (alreadyExists) {
            searchError.value = 'Symbol already in watchlist';
            isAdding.value = false;
            return;
          }
        }
      }

      isAdding.value = false;
    } catch (e) {
      searchError.value = e.toString();
      isAdding.value = false;
    }
  }

  void clearResults() {
    searchResults.value = [];
    searchError.value = null;
  }
}
