import 'package:equatable/equatable.dart';

final class PriceData extends Equatable {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? turnover;
  final DateTime? lastUpdate;

  const PriceData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.open,
    this.high,
    this.low,
    this.close,
    this.turnover,
    this.lastUpdate,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final prevClose = (json['previous_close'] as num?)?.toDouble() ?? 0;
    final change = price - prevClose;
    final changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0.0;

    return PriceData(
      symbol: json['symbol'] as String? ?? '',
      price: price,
      change: change,
      changePercent: changePercent,
      volume: int.tryParse(json['volume']?.toString() ?? '0') ?? 0,
      open: double.tryParse(json['open']?.toString() ?? ''),
      high: double.tryParse(json['high']?.toString() ?? ''),
      low: double.tryParse(json['low']?.toString() ?? ''),
      close: double.tryParse(json['close']?.toString() ?? ''),
      turnover: double.tryParse(json['turnover']?.toString() ?? ''),
      lastUpdate: json['last_update'] != null
          ? DateTime.tryParse(json['last_update'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        price,
        change,
        changePercent,
        volume,
        open,
        high,
        low,
        close,
        turnover,
        lastUpdate,
      ];
}

final class CandleData extends Equatable {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      open: (json['open'] as num?)?.toDouble() ?? 0,
      high: (json['high'] as num?)?.toDouble() ?? 0,
      low: (json['low'] as num?)?.toDouble() ?? 0,
      close: (json['close'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object> get props => [date, open, high, low, close, volume];
}
