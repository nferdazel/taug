import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // A11Y: Build semantic label including loading state.
    final String semanticLabel = isLoading ? '$label, loading' : label;

    return SizedBox(
      height: 32,
      child: Semantics(
        button: true,
        enabled: !isLoading && onPressed != null,
        label: semanticLabel,
        child: switch (variant) {
          AppButtonVariant.primary => ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: _buildIcon(),
              label: _buildLabel(),
            ),
          AppButtonVariant.secondary => OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: _buildIcon(),
              label: _buildLabel(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(AppColors.textPrimary),
                side: const BorderSide(color: Color(AppColors.border)),
              ),
            ),
          AppButtonVariant.ghost => TextButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: _buildIcon(),
              label: _buildLabel(),
            ),
          AppButtonVariant.danger => ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: _buildIcon(),
              label: _buildLabel(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.critical),
              ),
            ),
        },
      ),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon != null) return Icon(icon, size: 14);
    return const SizedBox.shrink();
  }

  Widget _buildLabel() {
    return Text(label, style: AppTypography.subheading);
  }
}
