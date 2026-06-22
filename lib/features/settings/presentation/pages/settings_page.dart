import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Settings workspace sections.
enum _SettingsSection {
  profile('PROFILE', Icons.person_outlined),
  workspace('WORKSPACE', Icons.desktop_windows_outlined),
  account('ACCOUNT', Icons.key_outlined);

  const _SettingsSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsProvider = SettingsProvider();
  final _authProvider = AuthProvider();
  _SettingsSection _activeSection = _SettingsSection.profile;

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left navigation (200px) ──
        SizedBox(width: 200, child: _buildNavigation()),
        // ── Divider ──
        const VerticalDivider(width: 1, thickness: 1, color: AppThemeColors.border),
        // ── Right content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: _buildSection(_activeSection),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────────────

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxl,
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SETTINGS', style: AppTypography.monoSection),
          const SizedBox(height: AppSpacing.xxl),
          ..._SettingsSection.values.map(_buildNavItem),
        ],
      ),
    );
  }

  Widget _buildNavItem(_SettingsSection section) {
    final bool isActive = _activeSection == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: isActive,
        label: section.label,
        child: InkWell(
          onTap: () => setState(() => _activeSection = section),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          focusColor: AppThemeColors.accent.withValues(alpha: 0.15),
          highlightColor: AppThemeColors.accent.withValues(alpha: 0.08),
          child: Container(
            height: AppSpacing.tableRowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isActive
                  ? AppThemeColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: AppSpacing.iconSize,
                  color: isActive
                      ? AppThemeColors.accent
                      : AppThemeColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  section.label,
                  style: AppTypography.monoLabel.copyWith(
                    color: isActive
                        ? AppThemeColors.textPrimary
                        : AppThemeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Section Router
  // ──────────────────────────────────────────────

  Widget _buildSection(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.profile:
        return _buildProfileSection();
      case _SettingsSection.workspace:
        return _buildWorkspaceSection();
      case _SettingsSection.account:
        return _buildAccountSection();
    }
  }

  // ──────────────────────────────────────────────
  // Profile Section
  // ──────────────────────────────────────────────

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROFILE', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.xxl),
        _buildProfileCard(),
        const SizedBox(height: AppSpacing.sectionGap),
        _buildTimezoneCard(),
      ],
    );
  }

  Widget _buildProfileCard() {
    return SignalBuilder(builder: (_) {
      return _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Username', _settingsProvider.username.value),
            const Divider(height: 1, color: AppThemeColors.border),
            _infoRow('Email', '${_settingsProvider.username.value}@taug.app'),
          ],
        ),
      );
    });
  }

  Widget _buildTimezoneCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timezone', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    SignalBuilder(builder: (_) {
                      return Text(
                        _getTimezoneLabel(_settingsProvider.timezone.value),
                        style: AppTypography.monoData,
                      );
                    }),
                  ],
                ),
              ),
              SignalBuilder(builder: (_) {
                return SizedBox(
                  height: AppSpacing.buttonHeight,
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
                      if (value != null) {
                        _settingsProvider.updateTimezone(value);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Workspace Section
  // ──────────────────────────────────────────────

  Widget _buildWorkspaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WORKSPACE', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.xxl),
        _buildDensityCard(),
      ],
    );
  }

  Widget _buildDensityCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Density Mode', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.md),
          SignalBuilder(builder: (_) {
            return Row(
              children: [
                _buildDensityChip(
                  'Compact',
                  'compact',
                  _settingsProvider.densityMode.value == 'compact',
                ),
                const SizedBox(width: AppSpacing.md),
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

  // A11Y: InkWell with Semantics for keyboard accessibility.
  Widget _buildDensityChip(String label, String value, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () => _settingsProvider.updateDensityMode(value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
        highlightColor: AppThemeColors.accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppThemeColors.accent : Colors.transparent,
            border: Border.all(
              color: selected ? AppThemeColors.accent : AppThemeColors.border,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
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
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Account Section
  // ──────────────────────────────────────────────

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACCOUNT', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.xxl),
        _buildAccountCard(),
      ],
    );
  }

  Widget _buildAccountCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sign out ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    SignalBuilder(builder: (_) {
                      return Text(
                        _settingsProvider.username.value,
                        style: AppTypography.monoData,
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  onPressed: () async {
                    await _authProvider.signOut();
                    if (!mounted) return;
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeColors.bearish,
                    side: const BorderSide(color: AppThemeColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                  ),
                  child: const Text(
                    AppStrings.logout,
                    style: AppTypography.monoLabel,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppThemeColors.border),
          // ── Version ──
          _infoRow('Version', '1.0.0'),
          const Divider(height: 1, color: AppThemeColors.border),
          _infoRow('Build', '1'),
          const Divider(height: 1, color: AppThemeColors.border),
          _infoRow('Platform', 'Web (WASM)'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Shared helpers
  // ──────────────────────────────────────────────

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(child: Text(value, style: AppTypography.monoData)),
        ],
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
