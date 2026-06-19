import 'package:equatable/equatable.dart';

final class Watchlist extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Watchlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        isDefault,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}

final class WatchlistItem extends Equatable {
  final String id;
  final String watchlistId;
  final int symbolId;
  final int sortOrder;
  final String? notes;
  final DateTime addedAt;
  final String? ticker;
  final String? name;
  final String? exchangeCode;
  final String? assetClass;

  const WatchlistItem({
    required this.id,
    required this.watchlistId,
    required this.symbolId,
    this.sortOrder = 0,
    this.notes,
    required this.addedAt,
    this.ticker,
    this.name,
    this.exchangeCode,
    this.assetClass,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      watchlistId: json['watchlist_id'] as String,
      symbolId: json['symbol_id'] as int,
      sortOrder: json['sort_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
      ticker: json['ticker'] as String?,
      name: json['name'] as String?,
      exchangeCode: json['exchange_code'] as String?,
      assetClass: json['asset_class'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        watchlistId,
        symbolId,
        sortOrder,
        notes,
        addedAt,
        ticker,
        name,
        exchangeCode,
        assetClass,
      ];
}
