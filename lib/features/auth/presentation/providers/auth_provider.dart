import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

class AuthProvider {
  final AuthRepository _repository;
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final isAuthenticated = Signal<bool>(false);

  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _init();
  }

  void _init() {
    isAuthenticated.value = _repository.currentUser != null;
    _authSubscription = _repository.authStateChanges.listen((state) {
      isAuthenticated.value = state.session != null;
    });
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  /// Validates password strength.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one digit (0-9)
  ///
  /// Returns null if valid, error message otherwise.
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  Future<void> signIn({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      error.value = 'Please fill in all fields';
      return;
    }

    isLoading.value = true;
    error.value = null;

    final result = await _repository.signIn(
      username: username,
      password: password,
    );

    isLoading.value = false;

    if (result.isSuccess && context.mounted) {
      context.go('/companies');
    } else if (result.isFailure) {
      // SECURITY: Generic error for sign-in to prevent username enumeration.
      // Never reveal whether the account exists or password is wrong.
      error.value = 'Invalid username or password';
    }
  }

  Future<void> signUp({
    required String username,
    required String password,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      error.value = 'Please fill in all fields';
      return;
    }

    if (password != confirmPassword) {
      error.value = 'Passwords do not match';
      return;
    }

    // SECURITY: Enforce strong password policy.
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      error.value = passwordError;
      return;
    }

    isLoading.value = true;
    error.value = null;

    final result = await _repository.signUp(
      username: username,
      password: password,
    );

    isLoading.value = false;

    if (result.isSuccess && context.mounted) {
      context.go('/companies');
    } else if (result.isFailure) {
      // SECURITY: Generic error for registration to prevent username enumeration.
      // Never reveal "user already exists" vs other registration failures.
      error.value = 'Registration failed. Please try a different username.';
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    isAuthenticated.value = false;
  }
}
