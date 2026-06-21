import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import '../../data/settings_repository.dart';

class SettingsProvider {
  final SettingsRepository _repository;

  final username = Signal<String>('');
  final timezone = Signal<String>('Asia/Jakarta');
  final densityMode = Signal<String>('compact');
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);

  SettingsProvider({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository();

  Future<void> loadSettings() async {
    isLoading.value = true;
    error.value = null;

    final profileResult = await _repository.getProfile();
    if (profileResult.isSuccess) {
      username.value = profileResult.data!['username'] as String? ?? '';
      timezone.value =
          profileResult.data!['timezone'] as String? ?? 'Asia/Jakarta';
    }

    final settingsResult = await _repository.getSettings();
    if (settingsResult.isSuccess) {
      densityMode.value =
          settingsResult.data!['density_mode'] as String? ?? 'compact';
    }

    isLoading.value = false;
  }

  Future<void> updateTimezone(String tz) async {
    final result = await _repository.updateProfile({'timezone': tz});
    if (result.isSuccess) {
      timezone.value = tz;
    } else {
      debugPrint('[SettingsProvider] updateTimezone failed: ${result.error}');
      error.value = result.error.toString();
    }
  }

  Future<void> updateDensityMode(String mode) async {
    final result = await _repository.updateSettings({'density_mode': mode});
    if (result.isSuccess) {
      densityMode.value = mode;
    } else {
      debugPrint('[SettingsProvider] updateDensityMode failed: ${result.error}');
      error.value = result.error.toString();
    }
  }
}
