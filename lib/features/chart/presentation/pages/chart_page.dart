import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/price_data.dart';
import '../../../../shared/widgets/price_cell.dart';
import '../providers/chart_provider.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final _provider = ChartProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadChartData();
    _provider.loadCurrentPrice();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildChart()),
        _buildInfoPanel(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Watch((_) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppThemeColors.border),
          ),
        ),
        child: Row(
          children: [
            _buildSymbolSelector(),
            const SizedBox(width: 12),
            _buildIntervalButtons(),
            const Spacer(),
            _buildPriceInfo(),
          ],
        ),
      );
    });
  }

  Widget _buildSymbolSelector() {
    return Watch((_) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppThemeColors.backgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppThemeColors.border),
        ),
        child: DropdownButton<String>(
          value: _provider.selectedSymbol.value,
          underline: const SizedBox(),
          dropdownColor: AppThemeColors.surface,
          style: AppTypography.monoSmall,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'BBCA.JK', child: Text('BBCA')),
            DropdownMenuItem(value: 'TLKM.JK', child: Text('TLKM')),
            DropdownMenuItem(value: 'AAPL', child: Text('AAPL')),
            DropdownMenuItem(value: 'MSFT', child: Text('MSFT')),
            DropdownMenuItem(value: 'BTC/USDT', child: Text('BTC')),
          ],
          onChanged: (value) {
            if (value != null) _provider.selectSymbol(value);
          },
        ),
      );
    });
  }

  Widget _buildIntervalButtons() {
    return Watch((_) {
      final intervals = ['1m', '5m', '15m', '1h', '1d', '1w', '1M'];
      return Row(
        children: intervals.map((interval) {
          final isSelected = _provider.selectedInterval.value == interval;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: SizedBox(
              height: 24,
              child: TextButton(
                onPressed: () => _provider.selectInterval(interval),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppThemeColors.accent
                      : AppThemeColors.backgroundLight,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  interval,
                  style: AppTypography.monoTiny.copyWith(
                    color: isSelected
                        ? AppThemeColors.textPrimary
                        : AppThemeColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildPriceInfo() {
    return Watch((_) {
      final price = _provider.currentPrice.value;
      if (price == null) return const SizedBox();

      return Row(
        children: [
          Text(
            price.price.toStringAsFixed(2),
            style: AppTypography.monoLarge,
          ),
          const SizedBox(width: 8),
          ChangeCell(value: price.changePercent),
        ],
      );
    });
  }

  Widget _buildChart() {
    return Watch((_) {
      final candles = _provider.candles.value;
      final isLoading = _provider.isLoading.value;

      if (isLoading) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (candles.isEmpty) {
        return const Center(
          child: Text(
            AppStrings.noData,
            style: AppTypography.bodySmall,
          ),
        );
      }

      return RepaintBoundary(
        child: SfCartesianChart(
          backgroundColor: AppThemeColors.background,
          plotAreaBorderWidth: 0,
          trackballBehavior: TrackballBehavior(
            enable: true,
            lineColor: AppThemeColors.textTertiary,
            lineWidth: 1,
            tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            enablePinching: true,
          ),
          series: <CandleSeries<CandleData, DateTime>>[
            CandleSeries<CandleData, DateTime>(
              dataSource: candles,
              xValueMapper: (CandleData candle, _) => candle.date,
              openValueMapper: (CandleData candle, _) => candle.open,
              highValueMapper: (CandleData candle, _) => candle.high,
              lowValueMapper: (CandleData candle, _) => candle.low,
              closeValueMapper: (CandleData candle, _) => candle.close,
              bullColor: AppThemeColors.bullish,
              bearColor: AppThemeColors.bearish,
              borderWidth: 1,
            ),
          ],
          primaryXAxis: const DateTimeAxis(
            majorGridLines: MajorGridLines(width: 0),
            axisLine: AxisLine(width: 1, color: AppThemeColors.border),
            labelStyle: AppTypography.monoTiny,
          ),
          primaryYAxis: const NumericAxis(
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: AppThemeColors.border,
            ),
            axisLine: AxisLine(width: 0),
            labelStyle: AppTypography.monoTiny,
          ),
        ),
      );
    });
  }

  Widget _buildInfoPanel() {
    return Watch((_) {
      final price = _provider.currentPrice.value;
      if (price == null) return const SizedBox();

      return Container(
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppThemeColors.border),
          ),
        ),
        child: Row(
          children: [
            _buildInfoItem('Open', price.open?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('High', price.high?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Low', price.low?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Close', price.close?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Volume', _formatVolume(price.volume)),
            _buildInfoItem('Turnover', price.turnover?.toStringAsFixed(0) ?? '-'),
          ],
        ),
      );
    });
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.monoTiny),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.monoSmall),
        ],
      ),
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
