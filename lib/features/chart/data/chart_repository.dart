import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
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
        body: {
          'symbol': symbol,
          'interval': interval,
          'limit': limit,
        },
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
      return Result.failure(
        DataSourceFailure(
          message: e.toString(),
          source: 'twelve_data',
        ),
      );
    }
  }

  Future<Result<PriceData>> getCurrentPrice(String symbol) async {
    try {
      final response = await _client.functions.invoke(
        'get-price',
        body: {'symbol': symbol},
      );

      if (response.data != null) {
        return Result.success(
          PriceData.fromJson(response.data as Map<String, dynamic>),
        );
      }

      return const Result.failure(
        DataSourceFailure(
          message: 'No price data',
          source: 'twelve_data',
        ),
      );
    } catch (e) {
      return Result.failure(
        DataSourceFailure(
          message: e.toString(),
          source: 'twelve_data',
        ),
      );
    }
  }
}
