import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/order_book_repository.dart';
import '../../data/trades_repository.dart';

class OrderBookPanel extends StatefulWidget {
  final String symbol;

  const OrderBookPanel({super.key, required this.symbol});

  @override
  State<OrderBookPanel> createState() => _OrderBookPanelState();
}

class _OrderBookPanelState extends State<OrderBookPanel> {
  final _repository = OrderBookRepository();
  final _orderBook = Signal<OrderBook?>(null);
  final _isLoading = Signal<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadOrderBook();
  }

  @override
  void didUpdateWidget(OrderBookPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _loadOrderBook();
    }
  }

  Future<void> _loadOrderBook() async {
    _isLoading.value = true;
    final result = await _repository.getOrderBook(widget.symbol);
    if (result.isSuccess) {
      _orderBook.value = result.data;
    }
    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final isLoading = _isLoading.value;
      final orderBook = _orderBook.value;

      if (isLoading) {
        return const Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
        );
      }

      if (orderBook == null) {
        return const Center(child: Text('No data', style: AppTypography.monoMeta));
      }

      return Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildAsks(orderBook.asks)),
          _buildSpread(orderBook),
          Expanded(child: _buildBids(orderBook.bids)),
        ],
      );
    });
  }

  Widget _buildHeader() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Price', style: AppTypography.monoSection)),
          SizedBox(width: 60, child: Text('Size', style: AppTypography.monoSection, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildAsks(List<OrderBookEntry> asks) {
    final reversed = asks.reversed.toList();
    final maxSize = reversed.fold<int>(0, (max, e) => e.size > max ? e.size : max);

    return ListView.builder(
      itemCount: reversed.length,
      itemExtent: 18,
      itemBuilder: (context, index) {
        final entry = reversed[index];
        final ratio = maxSize > 0 ? entry.size / maxSize : 0.0;

        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(color: AppThemeColors.bearish.withValues(alpha: 0.1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.price.toStringAsFixed(2),
                      style: AppTypography.monoMeta.copyWith(color: AppThemeColors.bearish),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.size.toString(),
                      style: AppTypography.monoMeta,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpread(OrderBook orderBook) {
    if (orderBook.asks.isEmpty || orderBook.bids.isEmpty) {
      return const SizedBox(height: 20);
    }
    final spread = orderBook.asks.first.price - orderBook.bids.first.price;
    final spreadPercent = orderBook.asks.first.price > 0
        ? (spread / orderBook.asks.first.price * 100)
        : 0;

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Spread: ', style: AppTypography.monoMeta),
          Text(
            '${spread.toStringAsFixed(2)} (${spreadPercent.toStringAsFixed(3)}%)',
            style: AppTypography.monoMeta.copyWith(color: AppThemeColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildBids(List<OrderBookEntry> bids) {
    final maxSize = bids.fold<int>(0, (max, e) => e.size > max ? e.size : max);

    return ListView.builder(
      itemCount: bids.length,
      itemExtent: 18,
      itemBuilder: (context, index) {
        final entry = bids[index];
        final ratio = maxSize > 0 ? entry.size / maxSize : 0.0;

        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(color: AppThemeColors.bullish.withValues(alpha: 0.1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.price.toStringAsFixed(2),
                      style: AppTypography.monoMeta.copyWith(color: AppThemeColors.bullish),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.size.toString(),
                      style: AppTypography.monoMeta,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
  final _repository = TradesRepository();
  final _trades = Signal<List<TradeEntry>>([]);
  final _isLoading = Signal<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  @override
  void didUpdateWidget(RunningTradesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _loadTrades();
    }
  }

  Future<void> _loadTrades() async {
    _isLoading.value = true;
    final result = await _repository.getRecentTrades(widget.symbol);
    if (result.isSuccess) {
      _trades.value = result.data!;
    }
    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final isLoading = _isLoading.value;
      final trades = _trades.value;

      if (isLoading) {
        return const Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
        );
      }

      if (trades.isEmpty) {
        return const Center(child: Text('No data', style: AppTypography.monoMeta));
      }

      return Column(
        children: [
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 48, child: Text('Time', style: AppTypography.monoSection)),
                Expanded(child: Text('Price', style: AppTypography.monoSection, textAlign: TextAlign.right)),
                SizedBox(width: 50, child: Text('Size', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: trades.length,
              itemExtent: 18,
              itemBuilder: (context, index) {
                final trade = trades[index];
                final isBuy = trade.side == 'buy';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          DateFormat('HH:mm:ss').format(trade.time),
                          style: AppTypography.monoMeta,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          trade.price.toStringAsFixed(2),
                          style: AppTypography.monoMeta.copyWith(
                            color: isBuy ? AppThemeColors.bullish : AppThemeColors.bearish,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          trade.size.toString(),
                          style: AppTypography.monoMeta,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
