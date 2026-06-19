import 'package:equatable/equatable.dart';

final class Symbol extends Equatable {
  final int id;
  final int exchangeId;
  final String ticker;
  final String name;
  final String assetClass;
  final String? sector;
  final String? industry;
  final int? marketCap;
  final bool isActive;

  const Symbol({
    required this.id,
    required this.exchangeId,
    required this.ticker,
    required this.name,
    required this.assetClass,
    this.sector,
    this.industry,
    this.marketCap,
    this.isActive = true,
  });

  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      id: json['id'] as int,
      exchangeId: json['exchange_id'] as int,
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      assetClass: json['asset_class'] as String,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      marketCap: json['market_cap'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exchange_id': exchangeId,
      'ticker': ticker,
      'name': name,
      'asset_class': assetClass,
      'sector': sector,
      'industry': industry,
      'market_cap': marketCap,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        exchangeId,
        ticker,
        name,
        assetClass,
        sector,
        industry,
        marketCap,
        isActive,
      ];
}
