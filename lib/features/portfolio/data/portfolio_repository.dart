import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/price_data.dart';
import '../domain/portfolio_entity.dart';

class PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<PortfolioHolding>>> getHoldings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      final response = await _client
          .from(AppSchema.portfolioHoldings)
          .select('''
            *,
            symbols!inner(id, ticker, name, exchanges!inner(code))
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final holdings = response.map((json) {
        final symbols = json['symbols'] as Map<String, dynamic>;
        final exchanges = symbols['exchanges'] as Map<String, dynamic>;
        return PortfolioHolding(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          symbolId: json['symbol_id'] as int,
          ticker: symbols['ticker'] as String?,
          name: symbols['name'] as String?,
          exchangeCode: exchanges['code'] as String?,
          quantity: (json['quantity'] as num).toDouble(),
          avgPrice: (json['avg_price'] as num).toDouble(),
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
        );
      }).toList();

      return Result.success(holdings);
    } catch (e) {
      debugPrint('[PortfolioRepo] getHoldings: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<PortfolioHolding>> addHolding({
    required int symbolId,
    required double quantity,
    required double avgPrice,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      final response = await _client
          .from(AppSchema.portfolioHoldings)
          .insert({
            'user_id': userId,
            'symbol_id': symbolId,
            'quantity': quantity,
            'avg_price': avgPrice,
          })
          .select()
          .single();

      return Result.success(PortfolioHolding.fromJson(response));
    } catch (e) {
      debugPrint('[PortfolioRepo] addHolding: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> updateHolding({
    required String holdingId,
    required double quantity,
    required double avgPrice,
  }) async {
    try {
      await _client
          .from(AppSchema.portfolioHoldings)
          .update({
            'quantity': quantity,
            'avg_price': avgPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', holdingId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[PortfolioRepo] updateHolding: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> removeHolding(String holdingId) async {
    try {
      await _client
          .from(AppSchema.portfolioHoldings)
          .delete()
          .eq('id', holdingId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[PortfolioRepo] removeHolding: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Map<String, PriceData>>> getPrices(List<String> tickers) async {
    try {
      final response = await _client
          .from(AppSchema.symbols)
          .select('ticker, quote_snapshots(*)')
          .inFilter('ticker', tickers);

      final Map<String, PriceData> priceMap = <String, PriceData>{};
      for (final row in response) {
        final Map<String, dynamic> symbolRow = Map<String, dynamic>.from(row);
        final String? ticker = symbolRow['ticker'] as String?;
        final Map<String, dynamic>? snapshot = _extractSnapshot(symbolRow);

        if (ticker != null && snapshot != null) {
          priceMap[ticker] = PriceData.fromJson({
            'symbol': ticker,
            ...snapshot,
          });
        }
      }

      return Result.success(priceMap);
    } catch (e) {
      debugPrint('[PortfolioRepo] getPrices: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Map<String, dynamic>? _extractSnapshot(Map<String, dynamic> row) {
    final Object? relation = row[AppSchema.quoteSnapshots];
    if (relation is Map<String, dynamic>) {
      return relation;
    }
    if (relation is List && relation.isNotEmpty && relation.first is Map) {
      return Map<String, dynamic>.from(relation.first as Map);
    }
    return null;
  }
}
