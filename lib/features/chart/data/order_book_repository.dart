import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';

class OrderBookEntry {
  final double price;
  final int size;

  const OrderBookEntry({required this.price, required this.size});
}

class OrderBook {
  final List<OrderBookEntry> asks;
  final List<OrderBookEntry> bids;
  final DateTime timestamp;

  const OrderBook({
    required this.asks,
    required this.bids,
    required this.timestamp,
  });
}

class OrderBookRepository {
  final SupabaseClient _client;

  OrderBookRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<OrderBook>> getOrderBook(String symbol) async {
    try {
      final response = await _client.functions.invoke(
        'get-price',
        body: {'symbol': symbol},
      );

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final volume = (data['volume'] as num?)?.toInt() ?? 0;

        final asks = <OrderBookEntry>[];
        final bids = <OrderBookEntry>[];

        for (var i = 1; i <= 10; i++) {
          final spread = price * 0.001 * i;
          final askSize = (volume * (0.1 + (0.05 * (10 - i)))).toInt().clamp(1, 99999);
          final bidSize = (volume * (0.1 + (0.05 * (10 - i)))).toInt().clamp(1, 99999);

          asks.add(OrderBookEntry(price: price + spread, size: askSize));
          bids.add(OrderBookEntry(price: price - spread, size: bidSize));
        }

        return Result.success(OrderBook(
          asks: asks,
          bids: bids,
          timestamp: DateTime.now(),
        ));
      }

      return const Result.failure(
        ServerFailure(message: 'No order book data'),
      );
    } catch (e) {
      debugPrint('[OrderBookRepo] getOrderBook: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
