import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/price_data.dart';

class MarketRepository {
  final SupabaseClient _client;

  MarketRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<PriceData>>> getTopMovers({int limit = 10}) async {
    try {
      final response = await _client
          .from(AppSchema.quoteSnapshots)
          .select('*, symbols!inner(ticker)')
          .eq('is_synthetic', false)
          .order('updated_at', ascending: false)
          .limit(200);

      final List<PriceData> validResults = response.map((row) {
        final Map<String, dynamic> snapshot = Map<String, dynamic>.from(row);
        final Map<String, dynamic> symbolRow = Map<String, dynamic>.from(
          snapshot['symbols'] as Map,
        );

        return PriceData.fromJson({'symbol': symbolRow['ticker'], ...snapshot});
      }).toList();

      validResults.sort(
        (a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()),
      );
      return Result.success(validResults.take(limit).toList());
    } catch (e) {
      debugPrint('[MarketRepo] getTopMovers: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> refreshQuoteSnapshots({int limit = 100}) async {
    try {
      await _client.functions.invoke(
        'refresh-quote-snapshots',
        body: {'limit': limit},
      );
      return const Result.success(null);
    } catch (e) {
      debugPrint('[MarketRepo] refreshQuoteSnapshots: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
