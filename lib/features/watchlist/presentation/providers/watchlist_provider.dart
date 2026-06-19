import 'package:signals/signals.dart';
import '../../../../shared/models/price_data.dart';
import '../../data/watchlist_repository.dart';
import '../../domain/watchlist_entity.dart';

class WatchlistProvider {
  final WatchlistRepository _repository;

  final watchlists = Signal<List<Watchlist>>([]);
  final currentWatchlist = Signal<Watchlist?>(null);
  final watchlistItems = Signal<List<WatchlistItem>>([]);
  final prices = Signal<List<PriceData>>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);

  WatchlistProvider({WatchlistRepository? repository})
      : _repository = repository ?? WatchlistRepository();

  Future<void> loadWatchlists() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getWatchlists();

    if (result.isSuccess) {
      watchlists.value = result.data!;
      if (result.data!.isNotEmpty && currentWatchlist.value == null) {
        currentWatchlist.value = result.data!.first;
        await loadWatchlistItems(result.data!.first.id);
      }
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> loadWatchlistItems(String watchlistId) async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getWatchlistItems(watchlistId);

    if (result.isSuccess) {
      watchlistItems.value = result.data!;
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> loadPrices() async {
    if (currentWatchlist.value == null) return;

    final result = await _repository.getWatchlistPrices(
      currentWatchlist.value!.id,
    );

    if (result.isSuccess) {
      prices.value = result.data!;
    }
  }

  Future<void> createWatchlist(String name) async {
    final result = await _repository.createWatchlist(name);
    if (result.isSuccess) {
      await loadWatchlists();
    }
  }

  Future<void> deleteWatchlist(String watchlistId) async {
    final result = await _repository.deleteWatchlist(watchlistId);
    if (result.isSuccess) {
      if (currentWatchlist.value?.id == watchlistId) {
        currentWatchlist.value = null;
        watchlistItems.value = [];
      }
      await loadWatchlists();
    }
  }

  Future<void> addToWatchlist(int symbolId) async {
    if (currentWatchlist.value == null) return;

    final result = await _repository.addToWatchlist(
      currentWatchlist.value!.id,
      symbolId,
    );

    if (result.isSuccess) {
      await loadWatchlistItems(currentWatchlist.value!.id);
    }
  }

  Future<void> removeFromWatchlist(String itemId) async {
    final result = await _repository.removeFromWatchlist(itemId);
    if (result.isSuccess && currentWatchlist.value != null) {
      await loadWatchlistItems(currentWatchlist.value!.id);
    }
  }

  void selectWatchlist(Watchlist watchlist) {
    currentWatchlist.value = watchlist;
    loadWatchlistItems(watchlist.id);
  }
}
