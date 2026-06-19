import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../errors/failures.dart';
import '../errors/result.dart';

class ApiClient {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;
  final Duration _timeout;

  ApiClient({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
    Duration? timeout,
  }) : _baseUrl = baseUrl ?? 'https://api.twelvedata.com',
       _apiKey = apiKey ?? AppEnv.twelveDataApiKey,
       _client = client ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 10);

  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl$path',
      ).replace(queryParameters: {'apikey': _apiKey, ...?queryParams});

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response.body);
        if (data != null) {
          return Result.success(data);
        }
        return const Result.failure(
          ServerFailure(message: 'Invalid response format'),
        );
      }

      return Result.failure(
        ServerFailure(
          message: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    } on TimeoutException {
      return const Result.failure(NetworkFailure(message: 'Request timed out'));
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl$path',
      ).replace(queryParameters: {'apikey': _apiKey, ...?queryParams});

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response.body);
        if (data != null && data.containsKey('data')) {
          final items = data['data'] as List;
          return Result.success(items.cast<Map<String, dynamic>>());
        }
        return const Result.success([]);
      }

      return Result.failure(
        ServerFailure(
          message: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    } on TimeoutException {
      return const Result.failure(NetworkFailure(message: 'Request timed out'));
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  Map<String, dynamic>? _parseResponse(String body) {
    try {
      final decoded = Map<String, dynamic>.from(
        const JsonDecoder().convert(body) as Map,
      );
      if (decoded.containsKey('code')) {
        return null;
      }
      return decoded;
    } catch (e) {
      debugPrint('[ApiClient._parseResponse] $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
