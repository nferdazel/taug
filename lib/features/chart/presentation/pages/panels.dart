import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/widgets/data_status_badge.dart';

class OrderBookPanel extends StatefulWidget {
  final String symbol;

  const OrderBookPanel({super.key, required this.symbol});

  @override
  State<OrderBookPanel> createState() => _OrderBookPanelState();
}

class _OrderBookPanelState extends State<OrderBookPanel> {
  @override
  Widget build(BuildContext context) {
    return const _UnavailableMarketPanel(
      title: 'Order Book Unavailable',
      detail: 'Real equity market depth requires a licensed source.',
    );
  }
}

class RunningTradesPanel extends StatefulWidget {
  final String symbol;

  const RunningTradesPanel({super.key, required this.symbol});

  @override
  State<RunningTradesPanel> createState() => _RunningTradesPanelState();
}

class _RunningTradesPanelState extends State<RunningTradesPanel> {
  @override
  Widget build(BuildContext context) {
    return const _UnavailableMarketPanel(
      title: 'Time & Sales Unavailable',
      detail:
          'Running trades are disabled until a licensed feed is integrated.',
    );
  }
}

class _UnavailableMarketPanel extends StatelessWidget {
  final String title;
  final String detail;

  const _UnavailableMarketPanel({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DataStatusBadge(origin: _unavailableOrigin),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.monoSection,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: AppTypography.monoMeta.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const DataOrigin _unavailableOrigin = DataOrigin(
  sourceLabel: 'Licensed Feed Required',
  latencyClass: DataLatencyClass.unavailable,
  isOfficial: false,
  isSynthetic: false,
);
