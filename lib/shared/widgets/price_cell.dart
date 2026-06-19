import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    return Text(
      value,
      style: AppThemeColors.changeStyle(change ?? 0).copyWith(
        fontSize: 11,
      ),
      textAlign: textAlign,
    );
  }
}

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

    return Text(
      showPercent ? '$prefix${value.toStringAsFixed(2)}%' : '$prefix${value.toStringAsFixed(2)}',
      style: AppTypography.monoSmall.copyWith(color: color),
      textAlign: textAlign,
    );
  }
}

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
    return Text(
      _formatVolume(value),
      style: AppTypography.monoTiny,
      textAlign: textAlign,
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}

class StatusDot extends StatelessWidget {
  final bool isConnected;

  const StatusDot({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? AppThemeColors.bullish : AppThemeColors.bearish,
      ),
    );
  }
}

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
    return Container(
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
    );
  }
}
