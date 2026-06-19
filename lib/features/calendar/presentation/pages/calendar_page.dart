import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/calendar_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _provider = CalendarProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadEvents();
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border),
        ),
      ),
      child: Row(
        children: [
          _buildDateSelector(),
          const SizedBox(width: 12),
          _buildCountryFilter(),
          const SizedBox(width: 12),
          _buildImportanceFilter(),
          const Spacer(),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Watch((_) {
      final date = _provider.selectedDate.value;
      return SizedBox(
        height: 24,
        child: TextButton.icon(
          onPressed: _showDatePicker,
          icon: const Icon(Icons.calendar_today, size: 12),
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
    return Watch((_) {
      final countries = ['all', 'US', 'EU', 'GB', 'JP', 'ID'];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppThemeColors.backgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppThemeColors.border),
        ),
        child: DropdownButton<String>(
          value: _provider.selectedCountry.value,
          underline: const SizedBox(),
          dropdownColor: AppThemeColors.surface,
          style: AppTypography.monoTiny,
          isDense: true,
          items: countries
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c == 'all' ? 'All' : c),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) _provider.selectCountry(value);
          },
        ),
      );
    });
  }

  Widget _buildImportanceFilter() {
    return Watch((_) {
      final current = _provider.minImportance.value;
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
      height: 24,
      width: 24,
      child: TextButton(
        onPressed: () => _provider.setMinImportance(level),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? AppThemeColors.accent
              : AppThemeColors.backgroundLight,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      height: 24,
      width: 24,
      child: IconButton(
        onPressed: () => _provider.refreshCalendar(),
        icon: const Icon(Icons.refresh, size: 14),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContent() {
    return Watch((_) {
      final events = _provider.events.value;
      final isLoading = _provider.isLoading.value;

      if (isLoading && events.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (events.isEmpty) {
        return const Center(
          child: Text(
            AppStrings.noData,
            style: AppTypography.bodySmall,
          ),
        );
      }

      return Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemExtent: 32,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventRow(event);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppThemeColors.backgroundLight,
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Text('Time', style: AppTypography.sectionHeader)),
          Expanded(flex: 3, child: Text('Event', style: AppTypography.sectionHeader)),
          SizedBox(width: 40, child: Text('Ctry', style: AppTypography.sectionHeader)),
          SizedBox(width: 30, child: Text('Imp', style: AppTypography.sectionHeader)),
          Expanded(flex: 2, child: Text('Actual', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Forecast', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Previous', style: AppTypography.sectionHeader, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildEventRow(dynamic event) {
    return Container(
      height: 32,
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
            child: Text(
              event.eventTime ?? '-',
              style: AppTypography.monoTiny,
            ),
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
            child: Text(
              event.country,
              style: AppTypography.monoTiny,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              _getImportanceEmoji(event.importance),
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
      initialDate: _provider.selectedDate.value,
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
      _provider.selectDate(picked);
    }
  }
}
