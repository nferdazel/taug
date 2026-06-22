import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../data/screener_repository.dart';

class ScreenerProvider {
  final ScreenerRepository _repository;

  final rows = ListSignal<Map<String, dynamic>>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  bool _isLoadingData = false;

  ScreenerProvider({ScreenerRepository? repository})
      : _repository = repository ?? ScreenerRepository();

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

    final result = await _repository.getScreenerResults();

    if (result.isSuccess) {
      rows.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
    _isLoadingData = false;
  }
}
