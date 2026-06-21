import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import '../../../../shared/models/price_data.dart';
import '../../data/watchlist_repository.dart';
import '../../domain/watchlist_entity.dart';

class WatchlistProvider {
  final WatchlistRepository _repository;

  final watchlists = Signal<List<Watchlist>>([]);
  final currentWatchlist = Signal<Watchlist?>(null);
  final watchlistItems = Signal<List<WatchlistItem>>([]);
  final prices = Signal<Map<String, PriceData>>({});
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final lastUpdated = Signal<DateTime?>(null);
  bool _isLoadingPrices = false;
  bool _isMutating = false;

  Timer? _refreshTimer;

  WatchlistProvider({WatchlistRepository? repository})
    : _repository = repository ?? WatchlistRepository();

  void dispose() {
    _refreshTimer?.cancel();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadPrices();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

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
      await loadPrices();
      startAutoRefresh();
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> loadPrices() async {
    if (_isLoadingPrices) return;
    if (currentWatchlist.value == null) return;
    if (watchlistItems.value.isEmpty) return;

    _isLoadingPrices = true;

    final tickers = watchlistItems.value
        .where((item) => item.ticker != null)
        .map((item) => item.ticker!)
        .toList();

    if (tickers.isEmpty) {
      _isLoadingPrices = false;
      return;
    }

    await _repository.refreshQuoteSnapshots(tickers);
    final result = await _repository.getPricesForSymbols(tickers);

    if (result.isSuccess) {
      prices.value = result.data!;
      lastUpdated.value = DateTime.now();
    }

    _isLoadingPrices = false;
  }

  Future<void> createWatchlist(String name) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.createWatchlist(name);
      if (result.isSuccess) {
        await loadWatchlists();
      } else {
        debugPrint('[WatchlistProvider] createWatchlist failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteWatchlist(String watchlistId) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.deleteWatchlist(watchlistId);
      if (result.isSuccess) {
        if (currentWatchlist.value?.id == watchlistId) {
          currentWatchlist.value = null;
          watchlistItems.value = [];
          stopAutoRefresh();
        }
        await loadWatchlists();
      } else {
        debugPrint('[WatchlistProvider] deleteWatchlist failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> addToWatchlist(int symbolId) async {
    if (currentWatchlist.value == null) return;
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.addToWatchlist(
        currentWatchlist.value!.id,
        symbolId,
      );

      if (result.isSuccess) {
        await loadWatchlistItems(currentWatchlist.value!.id);
      } else {
        debugPrint('[WatchlistProvider] addToWatchlist failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> removeFromWatchlist(String itemId) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.removeFromWatchlist(itemId);
      if (result.isSuccess && currentWatchlist.value != null) {
        await loadWatchlistItems(currentWatchlist.value!.id);
      } else if (!result.isSuccess) {
        debugPrint('[WatchlistProvider] removeFromWatchlist failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }

  void selectWatchlist(Watchlist watchlist) {
    stopAutoRefresh();
    currentWatchlist.value = watchlist;
    loadWatchlistItems(watchlist.id);
  }

  PriceData? getPriceForSymbol(String symbol) {
    return prices.value[symbol];
  }
}
