import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/shared/models/data_origin.dart';
import 'package:taug/shared/models/price_data.dart';

// ---------------------------------------------------------------------------
// Mock Supabase Client
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

class MockRealtimeClient extends Mock implements RealtimeClient {}

class MockChannel extends Mock implements RealtimeChannel {}

// ---------------------------------------------------------------------------
// Test Data Factories
// ---------------------------------------------------------------------------

/// Creates a [PriceData] with sensible defaults. Override any field as needed.
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

/// Creates a [DataOrigin] with sensible defaults.
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

/// Creates a raw JSON map matching the shape expected by [PriceData.fromJson].
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

/// Returns a fully wired [MockSupabaseClient] with common stubs.
///
/// Usage in tests:
/// ```dart
/// final client = createMockSupabaseClient();
/// // Then override specific stubs as needed:
/// when(() => client.from('watchlists')).thenReturn(mockBuilder);
/// ```
MockSupabaseClient createMockSupabaseClient() {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  final realtime = MockRealtimeClient();

  when(() => client.auth).thenReturn(auth);
  when(() => client.realtime).thenReturn(realtime);

  return client;
}
