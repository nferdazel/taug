import 'package:flutter/foundation.dart';

/// Centralized error sanitization for production safety.
///
/// In debug mode, full error details are logged and returned.
/// In release mode, generic messages are returned to prevent
/// information disclosure (schema details, stack traces, PII).
final class ErrorSanitizer {
  const ErrorSanitizer._();

  /// Returns a user-safe error message.
  ///
  /// In debug: full error string for developer visibility.
  /// In release: generic message to prevent information leakage.
  static String message(Object error) {
    if (kDebugMode) {
      return error.toString();
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Returns a user-safe auth error message.
  ///
  /// Never reveals whether an account exists or what internal
  /// validation failed beyond what the user already knows.
  static String authMessage(Object error) {
    if (kDebugMode) {
      debugPrint('[Auth] Raw error: $error');
      return error.toString();
    }
    return 'Authentication failed. Please check your credentials.';
  }

  /// Returns a user-safe registration error message.
  ///
  /// Prevents username enumeration by returning a generic message
  /// regardless of the underlying Supabase error.
  static String registrationMessage(Object error) {
    if (kDebugMode) {
      debugPrint('[Auth] Registration raw error: $error');
      return error.toString();
    }
    return 'Registration failed. Please try a different username.';
  }

  /// Logs an error only in debug mode.
  ///
  /// Prevents PII and internal details from leaking to console
  /// in production builds (Flutter Web WASM exposes console output).
  static void debugLog(String tag, Object error) {
    if (kDebugMode) {
      debugPrint('[$tag] $error');
    }
  }

  /// Logs a message only in debug mode.
  static void debugInfo(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }
}
