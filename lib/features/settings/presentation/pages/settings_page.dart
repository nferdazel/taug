import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsProvider = SettingsProvider();
  final _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _settingsProvider.loadSettings();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SETTINGS', style: AppTypography.monoSection),
              const SizedBox(height: 12),
              _buildProfileCard(),
              const SizedBox(height: 8),
              _buildTimezoneRow(),
              const SizedBox(height: 8),
              _buildDensityRow(),
              const Spacer(),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Watch((_) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppThemeColors.surface,
          border: Border.all(color: AppThemeColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROFILE', style: AppTypography.monoSection),
            const SizedBox(height: 6),
            _buildRow('Username', _settingsProvider.username.value),
            const SizedBox(height: 4),
            _buildRow('Email', '${_settingsProvider.username.value}@taug.app'),
          ],
        ),
      );
    });
  }

  Widget _buildTimezoneRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIMEZONE', style: AppTypography.monoSection),
          const SizedBox(height: 6),
          Watch((_) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    _getTimezoneLabel(_settingsProvider.timezone.value),
                    style: AppTypography.monoData,
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: DropdownButton<String>(
                    value: _settingsProvider.timezone.value,
                    underline: const SizedBox(),
                    dropdownColor: AppThemeColors.surface,
                    style: AppTypography.monoLabel,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Asia/Jakarta',
                        child: Text('WIB (UTC+7)'),
                      ),
                      DropdownMenuItem(
                        value: 'Asia/Makassar',
                        child: Text('WITA (UTC+8)'),
                      ),
                      DropdownMenuItem(
                        value: 'Asia/Jayapura',
                        child: Text('WIT (UTC+9)'),
                      ),
                      DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                      DropdownMenuItem(
                        value: 'America/New_York',
                        child: Text('EST (UTC-5)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) _settingsProvider.updateTimezone(value);
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDensityRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DENSITY', style: AppTypography.monoSection),
          const SizedBox(height: 6),
          Watch((_) {
            return Row(
              children: [
                _buildDensityChip(
                  'Compact',
                  'compact',
                  _settingsProvider.densityMode.value == 'compact',
                ),
                const SizedBox(width: 6),
                _buildDensityChip(
                  'Default',
                  'default',
                  _settingsProvider.densityMode.value == 'default',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDensityChip(String label, String value, bool selected) {
    return GestureDetector(
      onTap: () => _settingsProvider.updateDensityMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppThemeColors.accent : Colors.transparent,
          border: Border.all(
            color: selected ? AppThemeColors.accent : AppThemeColors.border,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: AppTypography.monoLabel.copyWith(
            color: selected
                ? AppThemeColors.textPrimary
                : AppThemeColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(width: 12),
        Text(value, style: AppTypography.monoData),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: () async {
          await _authProvider.signOut();
          if (!mounted) return;
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppThemeColors.bearish,
          side: const BorderSide(color: AppThemeColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text(AppStrings.logout, style: AppTypography.monoLabel),
      ),
    );
  }

  String _getTimezoneLabel(String tz) {
    const map = {
      'Asia/Jakarta': 'WIB (UTC+7)',
      'Asia/Makassar': 'WITA (UTC+8)',
      'Asia/Jayapura': 'WIT (UTC+9)',
      'UTC': 'UTC',
      'America/New_York': 'EST (UTC-5)',
    };
    return map[tz] ?? tz;
  }
}
