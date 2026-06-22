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
    // A11Y: Use Semantics with button + selected state for screen readers.
    // InkWell provides keyboard focus and activation via Enter/Space.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
        highlightColor: AppThemeColors.accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppThemeColors.accent.withValues(alpha: 0.15)
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
      ),
    );
  }
}
