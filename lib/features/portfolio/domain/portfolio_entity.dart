import 'package:equatable/equatable.dart';

final class PortfolioHolding extends Equatable {
  final String id;
  final String userId;
  final int symbolId;
  final String? ticker;
  final String? name;
  final String? exchangeCode;
  final double quantity;
  final double avgPrice;
  final double currentPrice;
  final double pnl;
  final double pnlPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PortfolioHolding({
    required this.id,
    required this.userId,
    required this.symbolId,
    this.ticker,
    this.name,
    this.exchangeCode,
    required this.quantity,
    required this.avgPrice,
    this.currentPrice = 0,
    this.pnl = 0,
    this.pnlPercent = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalValue => quantity * currentPrice;
  double get totalCost => quantity * avgPrice;

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      symbolId: json['symbol_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      avgPrice: (json['avg_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, symbolId, quantity, avgPrice];
}
