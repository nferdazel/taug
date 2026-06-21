import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';

/// High-frequency price display cell.
/// Wrapped in [RepaintBoundary] to isolate canvas redraws from
/// sibling/parent widget changes during real-time tick updates.
class PriceCell extends StatelessWidget {
  final String value;
  final double? change;
  final TextAlign textAlign;

  const PriceCell({
    super.key,
    required this.value,
    this.change,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final direction = (change ?? 0) >= 0 ? 'up' : 'down';
    return RepaintBoundary(
      child: Semantics(
        label: 'Price: $value, $direction',
        child: Text(
          value,
          style: AppThemeColors.changeStyle(change ?? 0).copyWith(
            fontSize: 11,
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// High-frequency change indicator cell.
/// Wrapped in [RepaintBoundary] to isolate canvas redraws — this widget
/// renders bullish/bearish colored text that flashes on every tick.
class ChangeCell extends StatelessWidget {
  final double value;
  final bool showPercent;
  final TextAlign textAlign;

  const ChangeCell({
    super.key,
    required this.value,
    this.showPercent = true,
    this.textAlign = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? AppThemeColors.bullish : AppThemeColors.bearish;
    final prefix = value >= 0 ? '+' : '';
    final direction = value >= 0 ? 'up' : 'down';
    final formatted = showPercent
        ? '$prefix${value.toStringAsFixed(2)}%'
        : '$prefix${value.toStringAsFixed(2)}';

    return RepaintBoundary(
      child: Semantics(
        label: 'Change: $direction ${value.abs().toStringAsFixed(2)} percent',
        child: Text(
          formatted,
          style: AppTypography.monoSmall.copyWith(color: color),
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// High-frequency volume display cell.
/// Wrapped in [RepaintBoundary] to isolate canvas redraws from
/// adjacent price/change cells updating on every tick.
class VolumeCell extends StatelessWidget {
  final int value;
  final TextAlign textAlign;

  const VolumeCell({
    super.key,
    required this.value,
    this.textAlign = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        label: 'Volume: ${formatVolume(value)}',
        child: Text(
          formatVolume(value),
          style: AppTypography.monoTiny,
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// Connection status indicator dot.
/// Wrapped in [RepaintBoundary] to prevent unnecessary repaints
/// when parent list rebuilds due to price ticks.
/// Uses [Semantics.liveRegion] so screen readers announce status changes.
class StatusDot extends StatelessWidget {
  final bool isConnected;

  const StatusDot({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final statusLabel = isConnected ? 'Connected' : 'Disconnected';
    return RepaintBoundary(
      child: Semantics(
        label: statusLabel,
        liveRegion: true,
        child: Tooltip(
          message: statusLabel,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppThemeColors.bullish : AppThemeColors.bearish,
            ),
          ),
        ),
      ),
    );
  }
}

/// Static section header — not high-frequency but included for consistency
/// with the data-cell repaint isolation pattern.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: AppTypography.sectionHeader,
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
