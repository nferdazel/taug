import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Result<User>> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final email = '$username@taug.app';
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return Result.success(response.user!);
      }

      return const Result.failure(AuthFailure(message: 'Sign in failed'));
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(message: e.message));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  Future<Result<User>> signUp({
    required String username,
    required String password,
  }) async {
    try {
      final email = '$username@taug.app';
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'app': 'taug'},
      );

      if (response.user != null) {
        return Result.success(response.user!);
      }

      return const Result.failure(AuthFailure(message: 'Sign up failed'));
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(message: e.message));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(message: e.message));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }
}
