import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_typography.dart';

abstract final class AppThemeColors {
  static const Color background = Color(AppColors.background);
  static const Color backgroundLight = Color(AppColors.backgroundLight);
  static const Color surface = Color(AppColors.surface);
  static const Color surfaceLight = Color(AppColors.surfaceLight);
  static const Color border = Color(AppColors.border);
  static const Color borderLight = Color(AppColors.borderLight);
  static const Color textPrimary = Color(AppColors.textPrimary);
  static const Color textSecondary = Color(AppColors.textSecondary);
  static const Color textTertiary = Color(AppColors.textTertiary);
  static const Color bullish = Color(AppColors.bullish);
  static const Color bullishLight = Color(AppColors.bullishLight);
  static const Color bearish = Color(AppColors.bearish);
  static const Color bearishLight = Color(AppColors.bearishLight);
  static const Color accent = Color(AppColors.accent);
  static const Color accentLight = Color(AppColors.accentLight);
  static const Color warning = Color(AppColors.warning);
  static const Color warningLight = Color(AppColors.warningLight);

  static TextStyle priceStyle(double change) {
    final color = change >= 0 ? bullish : bearish;
    return AppTypography.monoMedium.copyWith(color: color);
  }

  static TextStyle changeStyle(double change) {
    final color = change >= 0 ? bullish : bearish;
    return AppTypography.monoSmall.copyWith(color: color);
  }

  static TextStyle changePercentStyle(double change) {
    final color = change >= 0 ? bullish : bearish;
    return AppTypography.monoSmall.copyWith(color: color);
  }
}
