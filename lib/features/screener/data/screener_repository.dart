import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';

class ScreenerRepository {
  final SupabaseClient _client;

  ScreenerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<Map<String, dynamic>>>> getScreenerResults() async {
    try {
      final response = await _client
          .from(AppSchema.screenerResults)
          .select()
          .order('display_name');

      return Result.success(List<Map<String, dynamic>>.from(response as List));
    } catch (e) {
      debugPrint('[ScreenerRepo] getScreenerResults: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
