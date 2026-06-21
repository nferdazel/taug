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
  bool _isMutating = false;

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
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.updateProfile({'timezone': tz});
      if (result.isSuccess) {
        timezone.value = tz;
      } else {
        debugPrint('[SettingsProvider] updateTimezone failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> updateDensityMode(String mode) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.updateSettings({'density_mode': mode});
      if (result.isSuccess) {
        densityMode.value = mode;
      } else {
        debugPrint('[SettingsProvider] updateDensityMode failed: ${result.error}');
        error.value = result.error.toString();
      }
    } finally {
      _isMutating = false;
    }
  }
}
