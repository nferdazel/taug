import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

enum AppBadgeSize { small, medium }

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final AppBadgeSize size;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.size = AppBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = size == AppBadgeSize.small ? 10 : 11;
    final double iconSize = size == AppBadgeSize.small ? 7 : 8;
    final double hPad = size == AppBadgeSize.small ? 5 : 6;
    final double vPad = size == AppBadgeSize.small ? 2 : 3;

    // A11Y: Wrap badge in Semantics so screen readers announce the label.
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          // A11Y: Increase opacity from 0.20 to 0.25 for better contrast
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
