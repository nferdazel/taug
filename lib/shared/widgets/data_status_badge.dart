import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/data_origin.dart';

class DataStatusBadge extends StatelessWidget {
  final DataOrigin origin;

  const DataStatusBadge({super.key, required this.origin});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = _resolveColor();
    final String officialLabel = origin.isOfficial ? 'OFFICIAL' : 'SOURCE';

    return RepaintBoundary(
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildChip(origin.latencyClass.label, badgeColor),
          _buildChip(officialLabel, AppThemeColors.backgroundLight),
          _buildChip(
            origin.sourceLabel.toUpperCase(),
            AppThemeColors.backgroundLight,
          ),
          if (origin.isSynthetic)
            _buildChip('SYNTHETIC', AppThemeColors.warning),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTypography.monoTiny.copyWith(
          color: AppThemeColors.textPrimary,
        ),
      ),
    );
  }

  Color _resolveColor() {
    switch (origin.latencyClass) {
      case DataLatencyClass.realtime:
        return AppThemeColors.bullish;
      case DataLatencyClass.delayed:
        return AppThemeColors.accent;
      case DataLatencyClass.eod:
        return AppThemeColors.textTertiary;
      case DataLatencyClass.derived:
        return AppThemeColors.warning;
      case DataLatencyClass.syndicated:
        return AppThemeColors.accent;
      case DataLatencyClass.unavailable:
        return AppThemeColors.bearish;
    }
  }
}
