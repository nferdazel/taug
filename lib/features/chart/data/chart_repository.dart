import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/price_data.dart';

class ChartRepository {
  final SupabaseClient _client;

  ChartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<CandleData>>> getChartData({
    required String symbol,
    required String interval,
    int limit = 100,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'get-chart-data',
        body: {'symbol': symbol, 'interval': interval, 'limit': limit},
      );

      if (response.data != null) {
        final data = response.data as List;
        final candles = data
            .map((json) => CandleData.fromJson(json as Map<String, dynamic>))
            .toList();
        return Result.success(candles);
      }

      return const Result.success([]);
    } catch (e) {
      debugPrint('[ChartRepo] getChartData: $e');
      return Result.failure(
        DataSourceFailure(message: e.toString(), source: 'twelve_data'),
      );
    }
  }

  Future<Result<PriceData>> getCurrentPrice(String symbol) async {
    try {
      await _client.functions.invoke(
        'refresh-quote-snapshots',
        body: {
          'tickers': [symbol],
        },
      );

      final response = await _client
          .from(AppSchema.symbols)
          .select('ticker, quote_snapshots(*)')
          .eq('ticker', symbol)
          .maybeSingle();

      if (response != null) {
        final snapshot = extractRelationRow(response, AppSchema.quoteSnapshots);
        if (snapshot != null) {
          return Result.success(
            PriceData.fromJson({'symbol': response['ticker'], ...snapshot}),
          );
        }
      }

      return const Result.failure(
        DataSourceFailure(message: 'No price data', source: 'quote_snapshots'),
      );
    } catch (e) {
      debugPrint('[ChartRepo] getCurrentPrice: $e');
      return Result.failure(
        DataSourceFailure(message: e.toString(), source: 'quote_snapshots'),
      );
    }
  }

}
