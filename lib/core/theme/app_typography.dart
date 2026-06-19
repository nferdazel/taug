import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class AppTypography {
  // Font Families
  static const String mono = 'IBM Plex Mono';
  static const String sans = 'IBM Plex Sans';

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textSecondary),
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textSecondary),
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: sans,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textTertiary),
  );

  // Mono (financial data)
  static const TextStyle monoLarge = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle monoTiny = TextStyle(
    fontFamily: mono,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textSecondary),
  );

  // Section Headers (ALL CAPS)
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textSecondary),
    letterSpacing: 1.2,
  );

  // Compact Mode Variants
  static const TextStyle compactTitle = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle compactBody = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textPrimary),
  );

  static const TextStyle compactCaption = TextStyle(
    fontFamily: sans,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textSecondary),
  );

  static const TextStyle compactMono = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textPrimary),
  );
}
