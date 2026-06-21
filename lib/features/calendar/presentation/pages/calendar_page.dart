import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/models/econ_event.dart';
import '../../../../shared/widgets/data_status_badge.dart';
import '../../data/calendar_repository.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _repository = CalendarRepository();
  final _events = Signal<List<EconEvent>>([]);
  final _selectedDate = Signal<DateTime>(DateTime.now());
  final _selectedCountry = Signal<String>('all');
  final _minImportance = Signal<int>(1);
  final _isLoading = Signal<bool>(false);
  final _error = Signal<String?>(null);
  final _lastUpdated = Signal<DateTime?>(null);

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _events.dispose();
    _selectedDate.dispose();
    _selectedCountry.dispose();
    _minImportance.dispose();
    _isLoading.dispose();
    _error.dispose();
    _lastUpdated.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    _isLoading.value = true;
    _error.value = null;

    final result = await _repository.getEvents(
      date: _selectedDate.value,
      country: _selectedCountry.value,
      importance: _minImportance.value,
    );

    if (result.isSuccess) {
      _events.value = result.data!;
      _lastUpdated.value = DateTime.now();
    } else {
      _error.value = result.error.toString();
    }

    _isLoading.value = false;
  }

  Future<void> _refreshCalendar() async {
    await _repository.refreshCalendar();
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
      height: AppSpacing.tabBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildDateSelector(),
          const SizedBox(width: AppSpacing.xl),
          _buildCountryFilter(),
          const SizedBox(width: AppSpacing.xl),
          _buildImportanceFilter(),
          const SizedBox(width: AppSpacing.xl),
          const DataStatusBadge(origin: _calendarOrigin),
          const Spacer(),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SignalBuilder(builder: (_) {
      final date = _selectedDate.value;
      return SizedBox(
        height: AppSpacing.buttonHeight,
        child: TextButton.icon(
          onPressed: _showDatePicker,
          icon: const Icon(Icons.calendar_today, size: 14),
          label: Text(DateFormat('MMM d, yyyy').format(date)),
          style: TextButton.styleFrom(
            backgroundColor: AppThemeColors.backgroundLight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      );
    });
  }

  Widget _buildCountryFilter() {
    return SignalBuilder(builder: (_) {
      final countries = ['all', 'US', 'EU', 'GB', 'JP', 'ID', 'CN'];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppThemeColors.backgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppThemeColors.border),
        ),
        child: DropdownButton<String>(
          value: _selectedCountry.value,
          underline: const SizedBox(),
          dropdownColor: AppThemeColors.surface,
          style: AppTypography.monoLabel,
          isDense: true,
          items: countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c == 'all' ? 'All' : c),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _selectedCountry.value = value;
              _loadEvents();
            }
          },
        ),
      );
    });
  }

  Widget _buildImportanceFilter() {
    return SignalBuilder(builder: (_) {
      final current = _minImportance.value;
      return Row(
        children: [
          _buildImportanceButton(1, '⚪', current),
          const SizedBox(width: 2),
          _buildImportanceButton(2, '🟡', current),
          const SizedBox(width: 2),
          _buildImportanceButton(3, '🔴', current),
        ],
      );
    });
  }

  Widget _buildImportanceButton(int level, String emoji, int current) {
    final isSelected = current == level;
    return SizedBox(
      height: AppSpacing.buttonHeight,
      width: AppSpacing.buttonHeight,
      child: TextButton(
        onPressed: () {
          _minImportance.value = level;
          _loadEvents();
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? AppThemeColors.accent
              : AppThemeColors.backgroundLight,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SignalBuilder(builder: (_) {
      final isLoading = _isLoading.value;
      return SizedBox(
        height: AppSpacing.buttonHeight,
        width: AppSpacing.buttonHeight,
        child: IconButton(
          onPressed: isLoading ? null : _refreshCalendar,
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : const Icon(Icons.refresh, size: 16),
          padding: EdgeInsets.zero,
        ),
      );
    });
  }

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      final events = _events.value;
      final isLoading = _isLoading.value;
      final error = _error.value;

      if (isLoading && events.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && events.isEmpty) {
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
                error,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadEvents,
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
                Icons.calendar_today_outlined,
                size: 32,
                color: AppThemeColors.textTertiary,
              ),
              const SizedBox(height: 8),
              const Text(
                'No events for this date',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshCalendar,
                child: const Text('Fetch Events'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemExtent: 36,
              itemBuilder: (context, index) => _buildEventRow(events[index]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppThemeColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 50,
            child: Text('Time', style: AppTypography.sectionHeader),
          ),
          Expanded(
            flex: 3,
            child: Text('Event', style: AppTypography.sectionHeader),
          ),
          SizedBox(
            width: 40,
            child: Text('Ctry', style: AppTypography.sectionHeader),
          ),
          SizedBox(
            width: 30,
            child: Text('Imp', style: AppTypography.sectionHeader),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Actual',
              style: AppTypography.sectionHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Forecast',
              style: AppTypography.sectionHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Previous',
              style: AppTypography.sectionHeader,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(EconEvent event) {
    final importance = event.importance;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(event.eventTime ?? '-', style: AppTypography.monoTiny),
          ),
          Expanded(
            flex: 3,
            child: Text(
              event.title,
              style: AppTypography.monoSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(event.country, style: AppTypography.monoTiny),
          ),
          SizedBox(
            width: 30,
            child: Text(
              _getImportanceEmoji(importance),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.actual?.toString() ?? '-',
              style: AppTypography.monoSmall,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.forecast?.toString() ?? '-',
              style: AppTypography.monoSmall.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.previous?.toString() ?? '-',
              style: AppTypography.monoSmall.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getImportanceEmoji(int importance) {
    switch (importance) {
      case 3:
        return '🔴';
      case 2:
        return '🟡';
      default:
        return '⚪';
    }
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppThemeColors.accent,
              surface: AppThemeColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDate.value = picked;
      _loadEvents();
    }
  }
}

const DataOrigin _calendarOrigin = DataOrigin(
  sourceLabel: 'Calendar Pending API',
  latencyClass: DataLatencyClass.unavailable,
  isOfficial: false,
  isSynthetic: false,
);
