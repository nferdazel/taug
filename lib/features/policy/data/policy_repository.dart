import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../shared/models/policy_event.dart';

class PolicyRepository {
  final SupabaseClient _client;

  PolicyRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<List<PolicyEvent>>> getPolicyEvents({
    String? country,
    String? agency,
    int? minImportance,
    int limit = 50,
  }) async {
    try {
      var query = _client.from(AppSchema.policyEvents).select();

      if (country != null && country != 'all') {
        query = query.eq('country', country);
      }
      if (agency != null && agency != 'all') {
        query = query.eq('agency', agency);
      }
      if (minImportance != null) {
        query = query.gte('importance', minImportance);
      }

      final response = await query
          .order('published_at', ascending: false)
          .limit(limit);

      final List<PolicyEvent> rawEvents = response
          .map((json) => PolicyEvent.fromJson(json))
          .toList();
      final List<PolicyEvent> events = _dedupeEvents(rawEvents);
      return Result.success(events);
    } catch (e) {
      debugPrint('[PolicyRepo] getPolicyEvents: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> refreshPolicyEvents() async {
    try {
      await _client.functions.invoke('refresh-policy');
      return const Result.success(null);
    } catch (e) {
      debugPrint('[PolicyRepo] refreshPolicyEvents: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  List<PolicyEvent> _dedupeEvents(List<PolicyEvent> events) {
    final Set<String> seen = <String>{};
    final List<PolicyEvent> unique = <PolicyEvent>[];

    for (final PolicyEvent event in events) {
      final String key =
          '${event.agency}|${event.title.trim().toLowerCase()}|${event.publishedAt.toUtc().toIso8601String()}';
      if (seen.add(key)) {
        unique.add(event);
      }
    }

    return unique;
  }
}
