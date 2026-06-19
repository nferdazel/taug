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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(),
          _buildDivider(),
          _buildTimezoneSection(),
          _buildDivider(),
          _buildDensitySection(),
          _buildDivider(),
          _buildAccountSection(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppThemeColors.border);
  }

  Widget _buildProfileSection() {
    return Watch((_) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROFILE', style: AppTypography.sectionHeader),
            const SizedBox(height: 8),
            _buildInfoRow('Username', _settingsProvider.username.value),
            const SizedBox(height: 4),
            _buildInfoRow(
              'Email',
              '${_settingsProvider.username.value}@taug.app',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: AppTypography.bodySmall),
        const Spacer(),
        Text(value, style: AppTypography.monoSmall),
      ],
    );
  }

  Widget _buildTimezoneSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.timezone.toUpperCase(),
            style: AppTypography.sectionHeader,
          ),
          const SizedBox(height: 8),
          Watch((_) {
            return DropdownButton<String>(
              value: _settingsProvider.timezone.value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppThemeColors.surface,
              style: AppTypography.bodySmall,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDensitySection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.densityMode.toUpperCase(),
            style: AppTypography.sectionHeader,
          ),
          const SizedBox(height: 8),
          Watch((_) {
            return Row(
              children: [
                Expanded(
                  child: _buildDensityOption(
                    AppStrings.compact,
                    'compact',
                    _settingsProvider.densityMode.value == 'compact',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDensityOption(
                    AppStrings.default_,
                    'default',
                    _settingsProvider.densityMode.value == 'default',
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDensityOption(String label, String value, bool isSelected) {
    return InkWell(
      onTap: () => _settingsProvider.updateDensityMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.accent
              : AppThemeColors.backgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppThemeColors.accent : AppThemeColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? AppThemeColors.textPrimary
                : AppThemeColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACCOUNT', style: AppTypography.sectionHeader),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
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
                side: const BorderSide(color: AppThemeColors.bearish),
              ),
              child: const Text(AppStrings.logout),
            ),
          ),
        ],
      ),
    );
  }
}
