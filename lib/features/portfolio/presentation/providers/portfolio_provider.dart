import 'dart:async';
import 'package:signals/signals.dart';
import '../../../../shared/models/price_data.dart';
import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_entity.dart';

class PortfolioProvider {
  final PortfolioRepository _repository;

  final holdings = Signal<List<PortfolioHolding>>([]);
  final prices = Signal<Map<String, PriceData>>({});
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final lastUpdated = Signal<DateTime?>(null);

  Timer? _refreshTimer;

  PortfolioProvider({PortfolioRepository? repository})
      : _repository = repository ?? PortfolioRepository();

  void dispose() => _refreshTimer?.cancel();

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => loadPrices());
  }

  Future<void> loadHoldings() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getHoldings();

    if (result.isSuccess) {
      holdings.value = result.data!;
      await loadPrices();
      startAutoRefresh();
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> loadPrices() async {
    if (holdings.value.isEmpty) return;

    final tickers = holdings.value
        .where((h) => h.ticker != null)
        .map((h) => h.ticker!)
        .toList();

    if (tickers.isEmpty) return;

    final result = await _repository.getPrices(tickers);
    if (result.isSuccess) {
      prices.value = result.data!;
      lastUpdated.value = DateTime.now();
    }
  }

  Future<void> addHolding(int symbolId, double quantity, double avgPrice) async {
    final result = await _repository.addHolding(
      symbolId: symbolId,
      quantity: quantity,
      avgPrice: avgPrice,
    );

    if (result.isSuccess) {
      await loadHoldings();
    }
  }

  Future<void> updateHolding(String holdingId, double quantity, double avgPrice) async {
    final result = await _repository.updateHolding(
      holdingId: holdingId,
      quantity: quantity,
      avgPrice: avgPrice,
    );

    if (result.isSuccess) {
      await loadHoldings();
    }
  }

  Future<void> removeHolding(String holdingId) async {
    final result = await _repository.removeHolding(holdingId);
    if (result.isSuccess) {
      await loadHoldings();
    }
  }

  double get totalValue => holdings.value.fold(
    0,
    (sum, h) {
      final price = prices.value[h.ticker]?.price ?? 0;
      return sum + (h.quantity * price);
    },
  );

  double get totalCost => holdings.value.fold(
    0,
    (sum, h) => sum + (h.quantity * h.avgPrice),
  );

  double get totalPnL => totalValue - totalCost;

  double get totalPnLPercent => totalCost > 0 ? (totalPnL / totalCost) * 100 : 0;
}
