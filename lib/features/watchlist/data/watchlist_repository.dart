import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/price_data.dart';
import '../domain/watchlist_entity.dart';

class WatchlistRepository {
  final SupabaseClient _client;

  WatchlistRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<Watchlist>>> getWatchlists() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(AuthFailure(message: 'User not authenticated'));
      }

      final response = await _client
          .from('${AppSchema.name}.${AppSchema.watchlists}')
          .select()
          .eq('user_id', userId)
          .order('sort_order');

      final watchlists = response.map((json) => Watchlist.fromJson(json)).toList();
      return Result.success(watchlists);
    } catch (e) {
      debugPrint('[WatchlistRepo] getWatchlists: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Watchlist>> createWatchlist(String name) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(AuthFailure(message: 'User not authenticated'));
      }

      final response = await _client
          .from('${AppSchema.name}.${AppSchema.watchlists}')
          .insert({'user_id': userId, 'name': name})
          .select()
          .single();

      return Result.success(Watchlist.fromJson(response));
    } catch (e) {
      debugPrint('[WatchlistRepo] createWatchlist: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteWatchlist(String watchlistId) async {
    try {
      await _client
          .from('${AppSchema.name}.${AppSchema.watchlists}')
          .delete()
          .eq('id', watchlistId);
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WatchlistRepo] deleteWatchlist: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<List<WatchlistItem>>> getWatchlistItems(String watchlistId) async {
    try {
      final response = await _client
          .from('${AppSchema.name}.${AppSchema.watchlistItems}')
          .select('''
            *,
            symbols!inner(id, ticker, name, asset_class, exchanges!inner(code))
          ''')
          .eq('watchlist_id', watchlistId)
          .order('sort_order');

      final items = response.map((json) {
        final symbols = json['symbols'] as Map<String, dynamic>;
        final exchanges = symbols['exchanges'] as Map<String, dynamic>;
        return WatchlistItem(
          id: json['id'] as String,
          watchlistId: json['watchlist_id'] as String,
          symbolId: json['symbol_id'] as int,
          sortOrder: json['sort_order'] as int? ?? 0,
          notes: json['notes'] as String?,
          addedAt: DateTime.parse(json['added_at'] as String),
          ticker: symbols['ticker'] as String?,
          name: symbols['name'] as String?,
          exchangeCode: exchanges['code'] as String?,
          assetClass: symbols['asset_class'] as String?,
        );
      }).toList();

      return Result.success(items);
    } catch (e) {
      debugPrint('[WatchlistRepo] getWatchlistItems: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<WatchlistItem>> addToWatchlist(String watchlistId, int symbolId) async {
    try {
      final response = await _client
          .from('${AppSchema.name}.${AppSchema.watchlistItems}')
          .insert({'watchlist_id': watchlistId, 'symbol_id': symbolId})
          .select()
          .single();
      return Result.success(WatchlistItem.fromJson(response));
    } catch (e) {
      debugPrint('[WatchlistRepo] addToWatchlist: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> removeFromWatchlist(String itemId) async {
    try {
      await _client
          .from('${AppSchema.name}.${AppSchema.watchlistItems}')
          .delete()
          .eq('id', itemId);
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WatchlistRepo] removeFromWatchlist: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Map<String, PriceData>>> getPricesForSymbols(List<String> tickers) async {
    try {
      final Map<String, PriceData> priceMap = {};

      for (final ticker in tickers) {
        try {
          final response = await _client.functions.invoke(
            'get-price',
            body: {'symbol': ticker},
          );
          if (response.data != null) {
            final price = PriceData.fromJson(response.data as Map<String, dynamic>);
            priceMap[ticker] = price;
          }
        } catch (e) {
          debugPrint('[WatchlistRepo] getPricesForSymbols[$ticker]: $e');
        }
      }

      return Result.success(priceMap);
    } catch (e) {
      debugPrint('[WatchlistRepo] getPricesForSymbols: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
