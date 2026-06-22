import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/error_sanitizer.dart';

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
      // SECURITY: Never log PII (email) in production.
      // Flutter Web WASM exposes console output to end users.
      ErrorSanitizer.debugInfo('Auth', 'Signing in user');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        ErrorSanitizer.debugInfo('Auth', 'Sign in success');
        return Result.success(response.user!);
      }

      return const Result.failure(AuthFailure(message: 'Sign in failed'));
    } on AuthException catch (e) {
      ErrorSanitizer.debugLog('Auth', 'AuthException: ${e.message}');
      // SECURITY: Never expose raw Supabase auth errors to users.
      // They reveal whether an account exists (username enumeration).
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.authMessage(e)),
      );
    } catch (e) {
      ErrorSanitizer.debugLog('Auth', 'Unexpected sign-in error: $e');
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.authMessage(e)),
      );
    }
  }

  Future<Result<User>> signUp({
    required String username,
    required String password,
  }) async {
    try {
      final email = '$username@taug.app';
      // SECURITY: Never log PII (email) in production.
      ErrorSanitizer.debugInfo('Auth', 'Signing up user');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'app': 'taug'},
      );

      if (response.user != null) {
        ErrorSanitizer.debugInfo('Auth', 'Sign up success');
        return Result.success(response.user!);
      }

      return const Result.failure(AuthFailure(message: 'Sign up failed'));
    } on AuthException catch (e) {
      ErrorSanitizer.debugLog('Auth', 'AuthException: ${e.message}');
      // SECURITY: Use registration-specific message to prevent
      // username enumeration via error differentiation.
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.registrationMessage(e)),
      );
    } catch (e) {
      ErrorSanitizer.debugLog('Auth', 'Unexpected sign-up error: $e');
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.registrationMessage(e)),
      );
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Result.success(null);
    } on AuthException catch (e) {
      ErrorSanitizer.debugLog('Auth', 'SignOut error: ${e.message}');
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.authMessage(e)),
      );
    } catch (e) {
      ErrorSanitizer.debugLog('Auth', 'SignOut error: $e');
      return Result.failure(
        AuthFailure(message: ErrorSanitizer.authMessage(e)),
      );
    }
  }
}
