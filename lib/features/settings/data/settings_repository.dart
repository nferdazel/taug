import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<Map<String, dynamic>>> getSettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      final response = await _client
          .from('${AppSchema.name}.${AppSchema.userSettings}')
          .select()
          .eq('user_id', userId)
          .single();

      return Result.success(response);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  Future<Result<void>> updateSettings(Map<String, dynamic> updates) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      await _client
          .from('${AppSchema.name}.${AppSchema.userSettings}')
          .update(updates)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> getProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      final response = await _client
          .from('${AppSchema.name}.${AppSchema.profiles}')
          .select()
          .eq('id', userId)
          .single();

      return Result.success(response);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  Future<Result<void>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.failure(
          AuthFailure(message: 'User not authenticated'),
        );
      }

      await _client
          .from('${AppSchema.name}.${AppSchema.profiles}')
          .update(updates)
          .eq('id', userId);

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
