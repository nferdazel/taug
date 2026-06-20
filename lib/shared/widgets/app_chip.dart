import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppThemeColors.accent.withOpacity(0.15)
              : AppThemeColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppThemeColors.accent : AppThemeColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppThemeColors.accent : AppThemeColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
