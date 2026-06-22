import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../../shared/models/price_data.dart';
import '../../data/chart_repository.dart';

class ChartProvider {
  final ChartRepository _repository;

  final selectedSymbol = Signal<String>('BBCA.JK');
  final selectedInterval = Signal<String>('1d');
  final candles = Signal<List<CandleData>>([]);
  final currentPrice = Signal<PriceData?>(null);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);

  ChartProvider({ChartRepository? repository})
    : _repository = repository ?? ChartRepository();

  Future<void> loadChartData() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getChartData(
      symbol: selectedSymbol.value,
      interval: selectedInterval.value,
    );

    if (result.isSuccess) {
      candles.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
  }

  Future<void> loadCurrentPrice() async {
    final result = await _repository.getCurrentPrice(selectedSymbol.value);
    if (result.isSuccess) {
      currentPrice.value = result.data;
    }
  }

  void selectSymbol(String symbol) {
    selectedSymbol.value = symbol;
    loadChartData();
    loadCurrentPrice();
  }

  void selectInterval(String interval) {
    selectedInterval.value = interval;
    loadChartData();
  }
}
