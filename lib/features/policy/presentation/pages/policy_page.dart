import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/models/policy_event.dart';
import '../../../../shared/widgets/data_status_badge.dart';
import '../../data/policy_repository.dart';

class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  final PolicyRepository _repository = PolicyRepository();
  final _events = Signal<List<PolicyEvent>>([]);
  final _selectedCountry = Signal<String>('all');
  final _selectedAgency = Signal<String>('all');
  final _minImportance = Signal<int>(1);
  final _isLoading = Signal<bool>(false);
  final _error = Signal<String?>(null);
  final _lastUpdated = Signal<DateTime?>(null);

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    _isLoading.value = true;
    _error.value = null;

    final result = await _repository.getPolicyEvents(
      country: _selectedCountry.value,
      agency: _selectedAgency.value,
      minImportance: _minImportance.value,
    );

    if (result.isSuccess) {
      _events.value = result.data!;
      _lastUpdated.value = DateTime.now();
    } else {
      _error.value = result.error.toString();
    }

    _isLoading.value = false;
  }

  Future<void> _refreshEvents() async {
    await _repository.refreshPolicyEvents();
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildCountryFilter(),
          const SizedBox(width: AppSpacing.lg),
          _buildAgencyFilter(),
          const SizedBox(width: AppSpacing.lg),
          _buildImportanceFilter(),
          const SizedBox(width: AppSpacing.lg),
          const DataStatusBadge(origin: _policyOrigin),
          const Spacer(),
          if (_lastUpdated.value != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(
                'Updated ${DateFormat('HH:mm:ss').format(_lastUpdated.value!)}',
                style: AppTypography.monoTiny.copyWith(
                  color: AppThemeColors.textTertiary,
                ),
              ),
            ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCountryFilter() {
    return Watch((_) {
      const countries = ['all', 'US'];
      return _buildDropdown(
        value: _selectedCountry.value,
        items: countries,
        onChanged: (value) {
          _selectedCountry.value = value;
          _loadEvents();
        },
      );
    });
  }

  Widget _buildAgencyFilter() {
    return Watch((_) {
      const agencies = ['all', 'Federal Reserve', 'SEC'];
      return _buildDropdown(
        value: _selectedAgency.value,
        items: agencies,
        onChanged: (value) {
          _selectedAgency.value = value;
          _loadEvents();
        },
      );
    });
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppThemeColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: AppThemeColors.surface,
        style: AppTypography.monoLabel,
        isDense: true,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item == 'all' ? 'All' : item),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Widget _buildImportanceFilter() {
    return Watch((_) {
      return Row(
        children: [
          _buildImportanceChip(1, 'ALL'),
          const SizedBox(width: 4),
          _buildImportanceChip(2, 'MED+'),
          const SizedBox(width: 4),
          _buildImportanceChip(3, 'HIGH'),
        ],
      );
    });
  }

  Widget _buildImportanceChip(int level, String label) {
    final bool selected = _minImportance.value == level;
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: TextButton(
        onPressed: () {
          _minImportance.value = level;
          _loadEvents();
        },
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? AppThemeColors.accent
              : AppThemeColors.backgroundLight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
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

  Widget _buildRefreshButton() {
    return Watch((_) {
      return SizedBox(
        height: AppSpacing.buttonHeight,
        width: AppSpacing.buttonHeight,
        child: IconButton(
          onPressed: _isLoading.value ? null : _refreshEvents,
          padding: EdgeInsets.zero,
          icon: _isLoading.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : const Icon(Icons.refresh, size: 16),
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final events = _events.value;
      if (_isLoading.value && events.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (_error.value != null && events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 32,
                color: AppThemeColors.bearish,
              ),
              const SizedBox(height: 8),
              Text(
                _error.value!,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshEvents,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        );
      }

      if (events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 32,
                color: AppThemeColors.textTertiary,
              ),
              const SizedBox(height: 8),
              const Text('No policy events', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshEvents,
                child: const Text('Fetch Policy Feed'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshEvents,
        child: ListView.builder(
          itemCount: events.length,
          itemExtent: 124,
          itemBuilder: (context, index) => _buildPolicyItem(events[index]),
        ),
      );
    });
  }

  Widget _buildPolicyItem(PolicyEvent event) {
    final Color importanceColor = switch (event.importance) {
      3 => AppThemeColors.bearish,
      2 => AppThemeColors.warning,
      _ => AppThemeColors.accent,
    };

    return InkWell(
      onTap: () => _launchUrl(event.url),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: importanceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.agency.toUpperCase()} • ${event.country}',
                    style: AppTypography.monoLabel.copyWith(
                      color: AppThemeColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat(
                      'MMM d, HH:mm',
                    ).format(event.publishedAt.toLocal()),
                    style: AppTypography.monoLabel.copyWith(
                      color: AppThemeColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.summary != null && event.summary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  _buildTag(event.category),
                  _buildTag('IMP ${event.importance}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppThemeColors.backgroundLight,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.monoTiny.copyWith(
          color: AppThemeColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

const DataOrigin _policyOrigin = DataOrigin(
  sourceLabel: 'Official RSS',
  latencyClass: DataLatencyClass.syndicated,
  isOfficial: true,
  isSynthetic: false,
);
