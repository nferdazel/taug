import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        child: Semantics(
          button: onTap != null,
          label: semanticLabel,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
            highlightColor: AppThemeColors.accent.withValues(alpha: 0.1),
            child: Container(
              padding: padding ?? const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppThemeColors.border),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
