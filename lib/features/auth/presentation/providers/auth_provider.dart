import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';

import '../../data/auth_repository.dart';

class AuthProvider {
  final AuthRepository _repository;
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final isAuthenticated = Signal<bool>(false);

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _init();
  }

  void _init() {
    isAuthenticated.value = _repository.currentUser != null;
    _repository.authStateChanges.listen((state) {
      isAuthenticated.value = state.session != null;
    });
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
      context.go('/watchlist');
    } else if (result.isFailure) {
      error.value = (result.error as dynamic).message;
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

    if (password.length < 8) {
      error.value = 'Password must be at least 8 characters';
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
      context.go('/watchlist');
    } else if (result.isFailure) {
      error.value = (result.error as dynamic).message;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    isAuthenticated.value = false;
  }
}
