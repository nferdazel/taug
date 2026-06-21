import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/price_data.dart';

/// Top-level function for compute() — maps raw Supabase rows into sorted
/// PriceData entries off the main isolate.
List<PriceData> _parseTopMovers((List<dynamic>, int) args) {
  final (rawRows, limit) = args;

  final List<PriceData> results = <PriceData>[];
  for (int i = 0; i < rawRows.length; i++) {
    final Map<String, dynamic> snapshot =
        Map<String, dynamic>.from(rawRows[i] as Map);
    final Map<String, dynamic> symbolRow =
        Map<String, dynamic>.from(snapshot['symbols'] as Map);
    results.add(
      PriceData.fromJson({'symbol': symbolRow['ticker'], ...snapshot}),
    );
  }

  results.sort(
    (a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()),
  );
  return results.take(limit).toList();
}

class MarketRepository {
  final SupabaseClient _client;

  MarketRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<PriceData>>> getTopMovers({int limit = 10}) async {
    try {
      final List<dynamic> response = await _client
          .from(AppSchema.quoteSnapshots)
          .select('*, symbols!inner(ticker)')
          .eq('is_synthetic', false)
          .order('updated_at', ascending: false)
          .limit(200);

      final List<PriceData> validResults = await compute(
        _parseTopMovers,
        (response, limit),
      );
      return Result.success(validResults);
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
