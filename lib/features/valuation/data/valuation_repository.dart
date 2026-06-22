import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';

class ValuationRepository {
  final SupabaseClient _client;

  ValuationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<Map<String, dynamic>>>> getMetrics() async {
    try {
      final response = await _client
          .from(AppSchema.companyMetricSnapshot)
          .select()
          .order('metric_code');

      return Result.success(List<Map<String, dynamic>>.from(response as List));
    } catch (e) {
      debugPrint('[ValuationRepo] getMetrics: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
