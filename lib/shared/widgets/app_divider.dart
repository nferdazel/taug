import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';

class AppDivider extends StatelessWidget {
  final String? label;

  const AppDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return Row(
        children: [
          Expanded(child: Container(height: 1, color: AppThemeColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 10,
                color: AppThemeColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppThemeColors.border)),
        ],
      );
    }
    return Container(height: 1, color: AppThemeColors.border);
  }
}
