import 'package:flutter/material.dart';

import 'app_spacing.dart';
import '../constants/app_colors.dart';

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
          fontSize: 13,
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 11,
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
          borderSide: const BorderSide(color: Color(AppColors.accent)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
        ),
      ),
      dataTableTheme: const DataTableThemeData(
        headingTextStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textSecondary),
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 11,
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
