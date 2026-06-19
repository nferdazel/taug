import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import '../../../../shared/models/econ_event.dart';

class CalendarRepository {
  final SupabaseClient _client;

  CalendarRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<EconEvent>>> getEvents({
    DateTime? date,
    String? country,
    int? importance,
  }) async {
    try {
      var query = _client
          .from('${AppSchema.name}.${AppSchema.econEvents}')
          .select();

      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        query = query.eq('event_date', dateStr);
      }

      if (country != null && country != 'all') {
        query = query.eq('country', country);
      }

      if (importance != null) {
        query = query.gte('importance', importance);
      }

      final response = await query
          .order('event_date', ascending: true)
          .order('event_time', ascending: true);

      final events = response
          .map((json) => EconEvent.fromJson(json))
          .toList();

      return Result.success(events);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  Future<Result<void>> refreshCalendar() async {
    try {
      await _client.functions.invoke('refresh-calendar');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
