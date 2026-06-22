import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Typography system for Taug Financial Terminal
///
/// Scale (harmonious 10-15px range):
///   15 - heading
///   13 - subheading
///   12 - body/data
///   11 - caption/labels
///   10 - micro/meta
///
/// Sans: UI text, labels, buttons
/// Mono: Financial data, prices, numbers, code
abstract final class AppTypography {
  static const String mono = 'IBM Plex Mono';
  static const String sans = 'IBM Plex Sans';

  // ── Sans Scale ──

  /// 15px — Page titles, dialog headers
  static const TextStyle heading = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  /// 13px — Section titles, card headers
  static const TextStyle subheading = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  /// 12px — Primary body text and controls
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textPrimary),
  );

  /// 11px — Secondary text, descriptions
  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textSecondary),
  );

  /// 10px — Labels, hints, metadata
  static const TextStyle micro = TextStyle(
    fontFamily: sans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textTertiary),
  );

  /// 10px — Badge labels, small tags
  static const TextStyle microBadge = TextStyle(
    fontFamily: sans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  // ── Mono Scale ──

  /// 14px — Main price display
  static const TextStyle monoPrice = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textPrimary),
  );

  /// 12px — Table data, chart values
  static const TextStyle monoData = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textPrimary),
  );

  /// 11px — Column headers, field labels
  static const TextStyle monoLabel = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(AppColors.textSecondary),
  );

  /// 10px — Timestamps and metadata
  static const TextStyle monoMeta = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Color(AppColors.textSecondary),
  );

  /// 10px — Table section headers (ALL CAPS)
  static const TextStyle monoSection = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textTertiary),
    letterSpacing: 0.6,
  );

  // ── Semantic Aliases (backward compat) ──

  static const TextStyle displayLarge = heading;
  static const TextStyle displayMedium = subheading;
  static const TextStyle titleLarge = heading;
  static const TextStyle titleMedium = subheading;
  static const TextStyle titleSmall = subheading;
  static const TextStyle bodyLarge = body;
  static const TextStyle bodyMedium = body;
  static const TextStyle bodySmall = caption;
  static const TextStyle labelLarge = subheading;
  static const TextStyle labelMedium = caption;
  static const TextStyle labelSmall = micro;
  static const TextStyle monoLarge = monoPrice;
  static const TextStyle monoMedium = monoData;
  static const TextStyle monoSmall = monoLabel;
  static const TextStyle monoTiny = monoMeta;
  static const TextStyle sectionHeader = monoSection;
  static const TextStyle compactTitle = subheading;
  static const TextStyle compactBody = caption;
  static const TextStyle compactCaption = micro;
  static const TextStyle compactMono = monoLabel;
}
