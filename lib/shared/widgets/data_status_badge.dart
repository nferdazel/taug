import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/data_origin.dart';

class DataStatusBadge extends StatelessWidget {
  final DataOrigin origin;

  const DataStatusBadge({super.key, required this.origin});

  @override
  Widget build(BuildContext context) {
    // A11Y: Build a human-readable label for screen readers.
    final String semanticLabel = 'Data source: ${origin.sourceLabel}, '
        '${origin.latencyClass.label} latency'
        '${origin.isOfficial ? ', official' : ''}'
        '${origin.isSynthetic ? ', synthetic' : ''}';

    return RepaintBoundary(
      // A11Y: Wrap in Semantics so screen readers announce data origin.
      child: Semantics(
        label: semanticLabel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppThemeColors.backgroundLight,
            border: Border.all(color: AppThemeColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _resolveColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    origin.latencyClass.label.toUpperCase(),
                    style: AppTypography.monoTiny.copyWith(
                      color: AppThemeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildTextLabel(origin.isOfficial ? 'OFFICIAL' : 'SOURCE'),
              _buildTextLabel(origin.sourceLabel.toUpperCase()),
              if (origin.isSynthetic) _buildTextLabel('SYNTHETIC'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextLabel(String label) {
    return Text(
      label,
      style: AppTypography.monoTiny.copyWith(
        color: AppThemeColors.textSecondary,
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
