import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppThemeColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.subheading),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFF43F5E)),
            const SizedBox(height: 16),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MetricExplainer extends StatelessWidget {
  final String metric;
  final String explanation;

  const MetricExplainer({
    super.key,
    required this.metric,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: explanation,
      preferBelow: true,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(metric, style: AppTypography.body),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: 12, color: AppThemeColors.textTertiary),
        ],
      ),
    );
  }
}

class TrustExplainer extends StatelessWidget {
  final String label;
  final String explanation;
  final Color color;

  const TrustExplainer({
    super.key,
    required this.label,
    required this.explanation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: explanation,
      preferBelow: true,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppThemeColors.textPrimary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
