import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(AppColors.background),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.accent),
        secondary: Color(AppColors.accentLight),
        surface: Color(AppColors.surface),
        error: Color(AppColors.bearish),
        onPrimary: Color(AppColors.textPrimary),
        onSecondary: Color(AppColors.textPrimary),
        onSurface: Color(AppColors.textPrimary),
        onError: Color(AppColors.textPrimary),
      ),
      // A11Y: Global focus and highlight colors for keyboard navigation
      focusColor: const Color(AppColors.accent).withValues(alpha: 0.3),
      highlightColor: const Color(AppColors.accent).withValues(alpha: 0.1),
      hoverColor: const Color(AppColors.accent).withValues(alpha: 0.08),
      dividerColor: const Color(AppColors.border),
      visualDensity: VisualDensity.compact,
      iconTheme: const IconThemeData(
        color: Color(AppColors.textSecondary),
        size: 16,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(AppColors.border),
        thickness: 1,
        space: 0,
      ),
      cardTheme: const CardThemeData(
        color: Color(AppColors.surface),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: Color(AppColors.border)),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppColors.background),
        foregroundColor: Color(AppColors.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textPrimary),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(AppColors.textPrimary),
        unselectedLabelColor: Color(AppColors.textSecondary),
        indicatorColor: Color(AppColors.accent),
        labelStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Color(AppColors.border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.backgroundLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(AppColors.border)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(AppColors.border)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(AppColors.accent), width: 2),
        ),
        // A11Y: Error border for validation feedback
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(AppColors.bearish)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(AppColors.bearish), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 12,
          color: Color(AppColors.textTertiary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.accent),
          foregroundColor: const Color(AppColors.textPrimary),
          elevation: 0,
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          // A11Y: Focus indicator border for ElevatedButton
          side: WidgetStateBorderSide.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(AppColors.accent), width: 2);
            }
            return const BorderSide(color: Colors.transparent);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppColors.accent),
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          // A11Y: Focus indicator border for TextButton
          side: WidgetStateBorderSide.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(AppColors.accent), width: 2);
            }
            return const BorderSide(color: Colors.transparent);
          }),
        ),
      ),
      // A11Y: OutlinedButton with focus indicator
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppColors.textPrimary),
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          side: const BorderSide(color: Color(AppColors.border)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ).copyWith(
          side: WidgetStateBorderSide.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(AppColors.accent), width: 2);
            }
            return const BorderSide(color: Color(AppColors.border));
          }),
        ),
      ),
      dataTableTheme: const DataTableThemeData(
        headingTextStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textSecondary),
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 12,
          color: Color(AppColors.textPrimary),
        ),
        headingRowColor: WidgetStatePropertyAll(
          Color(AppColors.backgroundLight),
        ),
        dataRowColor: WidgetStatePropertyAll(Color(AppColors.background)),
        dividerThickness: 1,
        horizontalMargin: 0,
        columnSpacing: 16,
      ),
    );
  }
}
