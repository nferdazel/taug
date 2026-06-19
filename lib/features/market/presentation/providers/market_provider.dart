import 'dart:async';
import 'package:signals/signals.dart';
import '../../../../shared/models/price_data.dart';
import '../../data/market_repository.dart';

class MarketProvider {
  final MarketRepository _repository;

  final movers = Signal<List<PriceData>>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final lastUpdated = Signal<DateTime?>(null);
  bool _isLoadingMovers = false;

  Timer? _refreshTimer;

  MarketProvider({MarketRepository? repository})
    : _repository = repository ?? MarketRepository();

  void dispose() => _refreshTimer?.cancel();

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => loadMovers(),
    );
  }

  Future<void> loadMovers() async {
    if (_isLoadingMovers) return;
    _isLoadingMovers = true;
    if (movers.value.isEmpty) isLoading.value = true;
    error.value = null;

    await _repository.refreshQuoteSnapshots(limit: 100);
    final result = await _repository.getTopMovers();

    if (result.isSuccess) {
      movers.value = result.data!;
      lastUpdated.value = DateTime.now();
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
    _isLoadingMovers = false;
  }
}
