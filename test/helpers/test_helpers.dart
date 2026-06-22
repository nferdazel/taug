import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/shared/models/data_origin.dart';
import 'package:taug/shared/models/price_data.dart';

// ---------------------------------------------------------------------------
// Mock Supabase Client
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeClient extends Mock implements RealtimeClient {}

class MockChannel extends Mock implements RealtimeChannel {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Postgrest builders implement [Future<T>]. Dart's `await` protocol calls
/// [then] and expects the *callback* to be invoked with the result data.
/// mocktail's [thenAnswer] only provides a return value — it doesn't invoke
/// the callback — so `await mockBuilder` deadlocks.
///
/// The fix: override [then] to stash the response data and properly invoke
/// the onValue callback, just like a real Future would.
// ignore: must_be_immutable
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  Object? _stubData;
  bool _hasStub = false;
  bool _isError = false;

  /// Configure what this mock returns when awaited.
  void stubFuture(dynamic data) {
    _stubData = data;
    _hasStub = true;
    _isError = false;
  }

  /// Configure this mock to throw when awaited.
  void stubFutureError(Object error) {
    _stubData = error;
    _hasStub = true;
    _isError = true;
  }

  @override
  Future<T1> then<T1>(
    FutureOr<T1> Function(T value) onValue, {
    Function? onError,
  }) {
    if (!_hasStub) {
      return Completer<T1>().future; // never completes
    }
    if (_isError) {
      if (onError != null) {
        try {
          final result = onError(_stubData, StackTrace.current);
          if (result is Future<T1>) return result;
          return Future<T1>.value(result as T1);
        } catch (e) {
          return Future<T1>.error(e);
        }
      }
      return Future<T1>.error(_stubData!);
    }
    try {
      // Ensure list data has correct generic type to avoid
      // List<dynamic> vs List<Map<String, dynamic>> runtime errors.
      dynamic data = _stubData;
      data ??= <Map<String, dynamic>>[];
      if (data is List && data.isEmpty) {
        data = <Map<String, dynamic>>[];
      }
      // ignore: avoid_as
      final result = onValue(data as T);
      if (result is Future<T1>) return result;
      // ignore: avoid_as
      return Future<T1>.value(result as dynamic);
    } catch (e) {
      return Future<T1>.error(e);
    }
  }
}

// ignore: must_be_immutable
class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  Object? _stubData;
  bool _hasStub = false;
  bool _isError = false;

  void stubFuture(dynamic data) {
    _stubData = data;
    _hasStub = true;
    _isError = false;
  }

  void stubFutureError(Object error) {
    _stubData = error;
    _hasStub = true;
    _isError = true;
  }

  @override
  Future<T1> then<T1>(
    FutureOr<T1> Function(T value) onValue, {
    Function? onError,
  }) {
    if (!_hasStub) {
      return Completer<T1>().future;
    }
    if (_isError) {
      if (onError != null) {
        try {
          final result = onError(_stubData, StackTrace.current);
          if (result is Future<T1>) return result;
          return Future<T1>.value(result as T1);
        } catch (e) {
          return Future<T1>.error(e);
        }
      }
      return Future<T1>.error(_stubData!);
    }
    try {
      dynamic data = _stubData;
      data ??= <Map<String, dynamic>>[];
      if (data is List && data.isEmpty) {
        data = <Map<String, dynamic>>[];
      }
      // ignore: avoid_as
      final result = onValue(data as T);
      if (result is Future<T1>) return result;
      // ignore: avoid_as
      return Future<T1>.value(result as dynamic);
    } catch (e) {
      return Future<T1>.error(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Test Data Factories
// ---------------------------------------------------------------------------

PriceData createPriceData({
  String symbol = 'AAPL',
  double price = 150.00,
  double change = 2.50,
  double changePercent = 1.69,
  int volume = 50000000,
  double? open,
  double? high,
  double? low,
  double? close,
  double? turnover,
  DateTime? lastUpdate,
  DataOrigin? origin,
}) {
  return PriceData(
    symbol: symbol,
    price: price,
    change: change,
    changePercent: changePercent,
    volume: volume,
    open: open ?? 148.00,
    high: high ?? 152.00,
    low: low ?? 147.50,
    close: close ?? 150.00,
    turnover: turnover,
    lastUpdate: lastUpdate,
    origin: origin ?? createDataOrigin(),
  );
}

DataOrigin createDataOrigin({
  String sourceLabel = 'Twelve Data',
  DataLatencyClass latencyClass = DataLatencyClass.delayed,
  bool isOfficial = false,
  bool isSynthetic = false,
  DateTime? fetchedAt,
  DateTime? asOf,
}) {
  return DataOrigin(
    sourceLabel: sourceLabel,
    latencyClass: latencyClass,
    isOfficial: isOfficial,
    isSynthetic: isSynthetic,
    fetchedAt: fetchedAt,
    asOf: asOf,
  );
}

Map<String, dynamic> createPriceDataJson({
  String symbol = 'AAPL',
  double price = 150.00,
  double previousClose = 147.50,
  String volume = '50000000',
  String? open,
  String? high,
  String? low,
  String? close,
  String? turnover,
  String? lastUpdate,
}) {
  return {
    'symbol': symbol,
    'price': price,
    'previous_close': previousClose,
    'volume': volume,
    // ignore: use_null_aware_elements
    if (open != null) 'open': open,
    // ignore: use_null_aware_elements
    if (high != null) 'high': high,
    // ignore: use_null_aware_elements
    if (low != null) 'low': low,
    // ignore: use_null_aware_elements
    if (close != null) 'close': close,
    // ignore: use_null_aware_elements
    if (turnover != null) 'turnover': turnover,
    // ignore: use_null_aware_elements
    if (lastUpdate != null) 'last_update': lastUpdate,
  };
}

// ---------------------------------------------------------------------------
// Mock Supabase Setup Helper
// ---------------------------------------------------------------------------

MockSupabaseClient createMockSupabaseClient() {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  final realtime = MockRealtimeClient();

  when(() => client.auth).thenReturn(auth);
  when(() => client.realtime).thenReturn(realtime);

  return client;
}
