import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';

/// Show success snackbar after CRUD operations.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppThemeColors.textPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTypography.body)),
        ],
      ),
      backgroundColor: AppThemeColors.success,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Show error snackbar.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppThemeColors.textPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTypography.body)),
        ],
      ),
      backgroundColor: AppThemeColors.critical,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
