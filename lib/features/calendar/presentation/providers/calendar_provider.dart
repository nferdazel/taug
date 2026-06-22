import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../../shared/models/econ_event.dart';
import '../../data/calendar_repository.dart';

class CalendarProvider {
  final CalendarRepository _repository;

  final events = Signal<List<EconEvent>>([]);
  final selectedDate = Signal<DateTime>(DateTime.now());
  final selectedCountry = Signal<String>('all');
  final minImportance = Signal<int>(1);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);

  CalendarProvider({CalendarRepository? repository})
    : _repository = repository ?? CalendarRepository();

  Future<void> loadEvents() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getEvents(
      date: selectedDate.value,
      country: selectedCountry.value,
      importance: minImportance.value,
    );

    if (result.isSuccess) {
      events.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
  }

  Future<void> refreshCalendar() async {
    await _repository.refreshCalendar();
    await loadEvents();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadEvents();
  }

  void selectCountry(String country) {
    selectedCountry.value = country;
    loadEvents();
  }

  void setMinImportance(int importance) {
    minImportance.value = importance;
    loadEvents();
  }
}
