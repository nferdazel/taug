import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/price_data.dart';
import '../../../../shared/widgets/price_cell.dart';
import '../../data/chart_repository.dart';
import 'panels.dart';

enum ChartType { candle, line, area, ohlc }

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final _repository = ChartRepository();
  final _candles = Signal<List<CandleData>>([]);
  final _currentPrice = Signal<PriceData?>(null);
  final _isLoading = Signal<bool>(false);
  final _error = Signal<String?>(null);
  final _selectedSymbol = Signal<String>('AAPL');
  final _selectedInterval = Signal<String>('1d');
  final _selectedChartType = Signal<ChartType>(ChartType.candle);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading.value = true;
    _error.value = null;

    final priceResult = await _repository.getCurrentPrice(_selectedSymbol.value);
    if (priceResult.isSuccess) _currentPrice.value = priceResult.data;

    final chartResult = await _repository.getChartData(
      symbol: _selectedSymbol.value,
      interval: _selectedInterval.value,
    );

    if (chartResult.isSuccess) {
      _candles.value = chartResult.data!;
    } else {
      _error.value = chartResult.error.toString();
    }

    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(child: _buildChart()),
                    _buildInfoPanel(),
                  ],
                ),
              ),
              _buildSidePanels(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanels() {
    return Watch((_) {
      final symbol = _selectedSymbol.value;
      return Container(
        width: 220,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppThemeColors.border)),
        ),
        child: Column(
          children: [
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
                      ),
                      child: const TabBar(
                        tabs: [
                          Tab(text: 'Order Book'),
                          Tab(text: 'Trades'),
                        ],
                        labelStyle: AppTypography.monoMeta,
                        unselectedLabelStyle: AppTypography.monoMeta,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerHeight: 0,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          OrderBookPanel(symbol: symbol),
                          RunningTradesPanel(symbol: symbol),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          _buildSymbolSelector(),
          const SizedBox(width: 8),
          _buildChartTypeSelector(),
          const SizedBox(width: 8),
          _buildIntervalButtons(),
          const Spacer(),
          _buildPriceInfo(),
        ],
      ),
    );
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
          value: _selectedSymbol.value,
          underline: const SizedBox(),
          dropdownColor: AppThemeColors.surface,
          style: AppTypography.monoLabel,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'AAPL', child: Text('AAPL')),
            DropdownMenuItem(value: 'MSFT', child: Text('MSFT')),
            DropdownMenuItem(value: 'GOOGL', child: Text('GOOGL')),
            DropdownMenuItem(value: 'AMZN', child: Text('AMZN')),
            DropdownMenuItem(value: 'NVDA', child: Text('NVDA')),
            DropdownMenuItem(value: 'BBCA.JK', child: Text('BBCA')),
            DropdownMenuItem(value: 'TLKM.JK', child: Text('TLKM')),
            DropdownMenuItem(value: 'BTC/USDT', child: Text('BTC')),
            DropdownMenuItem(value: 'ETH/USDT', child: Text('ETH')),
            DropdownMenuItem(value: 'XAU/USD', child: Text('GOLD')),
          ],
          onChanged: (value) {
            if (value != null) {
              _selectedSymbol.value = value;
              _loadData();
            }
          },
        ),
      );
    });
  }

  Widget _buildChartTypeSelector() {
    return Watch((_) {
      final current = _selectedChartType.value;
      return Row(
        children: [
          _buildTypeButton(ChartType.candle, 'Candle', current),
          const SizedBox(width: 2),
          _buildTypeButton(ChartType.line, 'Line', current),
          const SizedBox(width: 2),
          _buildTypeButton(ChartType.area, 'Area', current),
          const SizedBox(width: 2),
          _buildTypeButton(ChartType.ohlc, 'OHLC', current),
        ],
      );
    });
  }

  Widget _buildTypeButton(ChartType type, String label, ChartType current) {
    final isSelected = current == type;
    return GestureDetector(
      onTap: () => _selectedChartType.value = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeColors.accent : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppThemeColors.accent : AppThemeColors.border,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: AppTypography.monoMeta.copyWith(
            color: isSelected
                ? AppThemeColors.textPrimary
                : AppThemeColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalButtons() {
    return Watch((_) {
      final intervals = ['1m', '5m', '15m', '1h', '1d', '1w', '1M'];
      return Row(
        children: intervals.map((interval) {
          final isSelected = _selectedInterval.value == interval;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: SizedBox(
              height: 22,
              child: TextButton(
                onPressed: () {
                  _selectedInterval.value = interval;
                  _loadData();
                },
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppThemeColors.accent
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: isSelected
                        ? AppThemeColors.accent
                        : AppThemeColors.border,
                  ),
                ),
                child: Text(
                  interval,
                  style: AppTypography.monoMeta.copyWith(
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
      final price = _currentPrice.value;
      if (price == null) return const SizedBox();

      return Row(
        children: [
          Text(price.price.toStringAsFixed(2), style: AppTypography.monoPrice),
          const SizedBox(width: 6),
          ChangeCell(value: price.changePercent),
        ],
      );
    });
  }

  Widget _buildChart() {
    return Watch((_) {
      final candles = _candles.value;
      final isLoading = _isLoading.value;
      final error = _error.value;
      final chartType = _selectedChartType.value;

      if (isLoading) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 24, color: AppThemeColors.bearish),
              const SizedBox(height: 6),
              Text(error, style: AppTypography.caption, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        );
      }

      if (candles.isEmpty) {
        return const Center(
          child: Text(AppStrings.noData, style: AppTypography.caption),
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
          series: _buildSeries(candles, chartType),
          primaryXAxis: const DateTimeAxis(
            majorGridLines: MajorGridLines(width: 0),
            axisLine: AxisLine(width: 1, color: AppThemeColors.border),
            labelStyle: AppTypography.monoMeta,
          ),
          primaryYAxis: const NumericAxis(
            majorGridLines: MajorGridLines(width: 0.5, color: AppThemeColors.border),
            axisLine: AxisLine(width: 0),
            labelStyle: AppTypography.monoMeta,
          ),
        ),
      );
    });
  }

  List<CartesianSeries<CandleData, DateTime>> _buildSeries(
    List<CandleData> candles,
    ChartType type,
  ) {
    switch (type) {
      case ChartType.candle:
        return [
          CandleSeries<CandleData, DateTime>(
            dataSource: candles,
            xValueMapper: (CandleData c, _) => c.date,
            openValueMapper: (CandleData c, _) => c.open,
            highValueMapper: (CandleData c, _) => c.high,
            lowValueMapper: (CandleData c, _) => c.low,
            closeValueMapper: (CandleData c, _) => c.close,
            bullColor: AppThemeColors.bullish,
            bearColor: AppThemeColors.bearish,
            borderWidth: 1,
          ),
        ];

      case ChartType.line:
        return [
          LineSeries<CandleData, DateTime>(
            dataSource: candles,
            xValueMapper: (CandleData c, _) => c.date,
            yValueMapper: (CandleData c, _) => c.close,
            color: AppThemeColors.accent,
            width: 1.5,
          ),
        ];

      case ChartType.area:
        return [
          AreaSeries<CandleData, DateTime>(
            dataSource: candles,
            xValueMapper: (CandleData c, _) => c.date,
            yValueMapper: (CandleData c, _) => c.close,
            color: AppThemeColors.accent.withValues(alpha: 0.15),
            borderColor: AppThemeColors.accent,
            borderWidth: 1.5,
          ),
        ];

      case ChartType.ohlc:
        return [
          HiloOpenCloseSeries<CandleData, DateTime>(
            dataSource: candles,
            xValueMapper: (CandleData c, _) => c.date,
            openValueMapper: (CandleData c, _) => c.open,
            highValueMapper: (CandleData c, _) => c.high,
            lowValueMapper: (CandleData c, _) => c.low,
            closeValueMapper: (CandleData c, _) => c.close,
            bullColor: AppThemeColors.bullish,
            bearColor: AppThemeColors.bearish,
            borderWidth: 1,
          ),
        ];
    }
  }

  Widget _buildInfoPanel() {
    return Watch((_) {
      final price = _currentPrice.value;
      if (price == null) return const SizedBox();

      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            _buildInfoItem('Open', price.open?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('High', price.high?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Low', price.low?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Close', price.close?.toStringAsFixed(2) ?? '-'),
            _buildInfoItem('Volume', _formatVolume(price.volume)),
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
          Text(label, style: AppTypography.monoMeta),
          const SizedBox(height: 1),
          Text(value, style: AppTypography.monoLabel),
        ],
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) return '${(volume / 1000000000).toStringAsFixed(1)}B';
    if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(1)}M';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}K';
    return volume.toString();
  }
}
