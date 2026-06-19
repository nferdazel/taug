import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../shared/models/price_data.dart';

class MarketRepository {
  final SupabaseClient _client;

  MarketRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<PriceData>>> getTopMovers({int limit = 10}) async {
    try {
      final symbols = [
        'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'META', 'TSLA',
        'JPM', 'V', 'WMT', 'BTC/USDT', 'ETH/USDT', 'XAU/USD',
      ];

      final futures = symbols.map((symbol) async {
        try {
          final response = await _client.functions.invoke(
            'get-price',
            body: {'symbol': symbol},
          );
          if (response.data != null) {
            return PriceData.fromJson(response.data as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('[MarketRepo] getTopMovers[$symbol]: $e');
        }
        return null;
      });

      final results = await Future.wait(futures);
      final validResults = results.whereType<PriceData>().toList();
      validResults.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
      return Result.success(validResults.take(limit).toList());
    } catch (e) {
      debugPrint('[MarketRepo] getTopMovers: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
