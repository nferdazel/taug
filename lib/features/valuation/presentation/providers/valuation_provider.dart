import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../data/valuation_repository.dart';

class ValuationProvider {
  final ValuationRepository _repository;

  final rows = ListSignal<Map<String, dynamic>>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  bool _isLoadingData = false;

  ValuationProvider({ValuationRepository? repository})
      : _repository = repository ?? ValuationRepository();

  void dispose() {
    rows.dispose();
    isLoading.dispose();
    error.dispose();
  }

  Future<void> load() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getMetrics();

    if (result.isSuccess) {
      rows.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
    _isLoadingData = false;
  }
}
