import 'package:flutter_test/flutter_test.dart';
import 'package:taug/shared/models/data_origin.dart';
import 'package:taug/shared/models/price_data.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('PriceData', () {
    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------
    group('constructor', () {
      test('creates instance with all required fields', () {
        final origin = createDataOrigin();
        final now = DateTime(2026, 6, 22, 10, 30);

        final priceData = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          open: 148.00,
          high: 152.00,
          low: 147.50,
          close: 150.00,
          turnover: 7500000000.0,
          lastUpdate: now,
          origin: origin,
        );

        expect(priceData.symbol, 'AAPL');
        expect(priceData.price, 150.00);
        expect(priceData.change, 2.50);
        expect(priceData.changePercent, 1.69);
        expect(priceData.volume, 50000000);
        expect(priceData.open, 148.00);
        expect(priceData.high, 152.00);
        expect(priceData.low, 147.50);
        expect(priceData.close, 150.00);
        expect(priceData.turnover, 7500000000.0);
        expect(priceData.lastUpdate, now);
        expect(priceData.origin, origin);
      });

      test('creates instance with only required fields (optionals null)', () {
        final priceData = PriceData(
          symbol: 'TSLA',
          price: 250.00,
          change: -5.00,
          changePercent: -1.96,
          volume: 30000000,
          origin: createDataOrigin(),
        );

        expect(priceData.symbol, 'TSLA');
        expect(priceData.open, isNull);
        expect(priceData.high, isNull);
        expect(priceData.low, isNull);
        expect(priceData.close, isNull);
        expect(priceData.turnover, isNull);
        expect(priceData.lastUpdate, isNull);
      });

      test('accepts zero values', () {
        final priceData = PriceData(
          symbol: 'ZERO',
          price: 0,
          change: 0,
          changePercent: 0,
          volume: 0,
          origin: createDataOrigin(),
        );

        expect(priceData.price, 0);
        expect(priceData.change, 0);
        expect(priceData.changePercent, 0);
        expect(priceData.volume, 0);
      });

      test('accepts negative change values (bearish)', () {
        final priceData = PriceData(
          symbol: 'BEAR',
          price: 100.00,
          change: -3.50,
          changePercent: -3.38,
          volume: 1000000,
          origin: createDataOrigin(),
        );

        expect(priceData.change, isNegative);
        expect(priceData.changePercent, isNegative);
      });
    });

    // -----------------------------------------------------------------------
    // Equatable / equality
    // -----------------------------------------------------------------------
    group('equality', () {
      test('two instances with same field values are equal', () {
        final origin = createDataOrigin();
        final a = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );
        final b = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two instances with different symbol are not equal', () {
        final origin = createDataOrigin();
        final a = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );
        final b = PriceData(
          symbol: 'TSLA',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );

        expect(a, isNot(equals(b)));
      });

      test('two instances with different price are not equal', () {
        final origin = createDataOrigin();
        final a = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );
        final b = PriceData(
          symbol: 'AAPL',
          price: 155.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: origin,
        );

        expect(a, isNot(equals(b)));
      });

      test('two instances with different origin are not equal', () {
        final a = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: createDataOrigin(sourceLabel: 'Twelve Data'),
        );
        final b = PriceData(
          symbol: 'AAPL',
          price: 150.00,
          change: 2.50,
          changePercent: 1.69,
          volume: 50000000,
          origin: createDataOrigin(sourceLabel: 'Yahoo Finance'),
        );

        expect(a, isNot(equals(b)));
      });

      test('factory helper produces equal instances', () {
        // DataOrigin does NOT extend Equatable, so we must share the same
        // instance to get value equality through PriceData.props.
        final sharedOrigin = createDataOrigin();
        final a = createPriceData(origin: sharedOrigin);
        final b = createPriceData(origin: sharedOrigin);

        expect(a, equals(b));
      });
    });

    // -----------------------------------------------------------------------
    // copyWith (manual verification — PriceData uses Equatable, no copyWith)
    // -----------------------------------------------------------------------
    group('field immutability', () {
      test('all fields are final (compile-time guarantee)', () {
        final priceData = createPriceData();

        // Accessing all fields to verify they are readable
        expect(priceData.symbol, isA<String>());
        expect(priceData.price, isA<double>());
        expect(priceData.change, isA<double>());
        expect(priceData.changePercent, isA<double>());
        expect(priceData.volume, isA<int>());
        expect(priceData.open, isA<double?>());
        expect(priceData.high, isA<double?>());
        expect(priceData.low, isA<double?>());
        expect(priceData.close, isA<double?>());
        expect(priceData.turnover, isA<double?>());
        expect(priceData.lastUpdate, isA<DateTime?>());
        expect(priceData.origin, isA<DataOrigin>());
      });

      test('creating a new instance with different values is independent', () {
        final original = createPriceData(price: 100.00);
        final updated = PriceData(
          symbol: original.symbol,
          price: 200.00,
          change: original.change,
          changePercent: original.changePercent,
          volume: original.volume,
          origin: original.origin,
        );

        expect(original.price, 100.00);
        expect(updated.price, 200.00);
        expect(original, isNot(equals(updated)));
      });
    });

    // -----------------------------------------------------------------------
    // fromJson
    // -----------------------------------------------------------------------
    group('fromJson()', () {
      test('parses a complete JSON map correctly', () {
        final json = createPriceDataJson(
          symbol: 'MSFT',
          price: 420.50,
          previousClose: 415.00,
          volume: '25000000',
          open: '416.00',
          high: '422.00',
          low: '414.00',
          close: '420.50',
          turnover: '10500000000',
          lastUpdate: '2026-06-22T10:30:00Z',
        );

        final priceData = PriceData.fromJson(json);

        expect(priceData.symbol, 'MSFT');
        expect(priceData.price, 420.50);
        expect(priceData.change, closeTo(5.50, 0.001));
        expect(priceData.changePercent, closeTo(1.325, 0.01));
        expect(priceData.volume, 25000000);
        expect(priceData.open, 416.00);
        expect(priceData.high, 422.00);
        expect(priceData.low, 414.00);
        expect(priceData.close, 420.50);
        expect(priceData.turnover, 10500000000.0);
        expect(priceData.lastUpdate, isNotNull);
      });

      test('handles missing optional fields gracefully', () {
        final json = {
          'symbol': 'AAPL',
          'price': 150.0,
          'previous_close': 147.5,
          'volume': '1000',
        };

        final priceData = PriceData.fromJson(json);

        expect(priceData.symbol, 'AAPL');
        expect(priceData.open, isNull);
        expect(priceData.high, isNull);
        expect(priceData.low, isNull);
        expect(priceData.close, isNull);
        expect(priceData.turnover, isNull);
        expect(priceData.lastUpdate, isNull);
      });

      test('defaults to empty string and zeros when JSON is empty', () {
        final priceData = PriceData.fromJson(<String, dynamic>{});

        expect(priceData.symbol, '');
        expect(priceData.price, 0);
        expect(priceData.change, 0);
        expect(priceData.changePercent, 0);
        expect(priceData.volume, 0);
      });

      test('handles string-typed numeric fields for OHLC and volume', () {
        // price and previous_close use `as num?` cast (must be numeric).
        // open/high/low/close/turnover/volume use tryParse, so they accept strings.
        final json = {
          'symbol': 'BTC',
          'price': 65000.50,
          'previous_close': 64000.0,
          'volume': '12345',
          'open': '64500',
          'high': '66000',
          'low': '63500',
          'close': '65000.50',
        };

        final priceData = PriceData.fromJson(json);

        expect(priceData.price, 65000.50);
        expect(priceData.volume, 12345);
        expect(priceData.open, 64500.0);
        expect(priceData.high, 66000.0);
        expect(priceData.low, 63500.0);
        expect(priceData.close, 65000.50);
      });

      test('computes change and changePercent from price and previous_close',
          () {
        final json = {
          'symbol': 'TEST',
          'price': 110.0,
          'previous_close': 100.0,
          'volume': '1',
        };

        final priceData = PriceData.fromJson(json);

        expect(priceData.change, 10.0);
        expect(priceData.changePercent, 10.0);
      });

      test('handles zero previous_close without division error', () {
        final json = {
          'symbol': 'ZERO',
          'price': 5.0,
          'previous_close': 0,
          'volume': '1',
        };

        final priceData = PriceData.fromJson(json);

        expect(priceData.change, 5.0);
        expect(priceData.changePercent, 0.0);
      });
    });
  });

  // ==========================================================================
  // CandleData
  // ==========================================================================
  group('CandleData', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final date = DateTime(2026, 6, 22);
        final candle = CandleData(
          date: date,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 1000000,
        );

        expect(candle.date, date);
        expect(candle.open, 100.0);
        expect(candle.high, 110.0);
        expect(candle.low, 95.0);
        expect(candle.close, 105.0);
        expect(candle.volume, 1000000);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final date = DateTime(2026, 6, 22);
        final a = CandleData(
          date: date,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 1000000,
        );
        final b = CandleData(
          date: date,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 1000000,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different volume produces inequality', () {
        final date = DateTime(2026, 6, 22);
        final a = CandleData(
          date: date,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 1000000,
        );
        final b = CandleData(
          date: date,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 2000000,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('fromJson()', () {
      test('parses a valid JSON map', () {
        final json = {
          'date': '2026-06-22T00:00:00',
          'open': 100.0,
          'high': 110.0,
          'low': 95.0,
          'close': 105.0,
          'volume': 1000000,
        };

        final candle = CandleData.fromJson(json);

        expect(candle.date, DateTime(2026, 6, 22));
        expect(candle.open, 100.0);
        expect(candle.high, 110.0);
        expect(candle.low, 95.0);
        expect(candle.close, 105.0);
        expect(candle.volume, 1000000);
      });

      test('handles missing date by falling back to now', () {
        final json = {
          'open': 100.0,
          'high': 110.0,
          'low': 95.0,
          'close': 105.0,
          'volume': 500,
        };

        final candle = CandleData.fromJson(json);

        // date falls back to DateTime.now(), so just verify it exists
        expect(candle.date, isA<DateTime>());
      });

      test('handles null and missing numeric fields with zero defaults', () {
        final json = <String, dynamic>{
          'date': '2026-01-01',
        };

        final candle = CandleData.fromJson(json);

        expect(candle.open, 0);
        expect(candle.high, 0);
        expect(candle.low, 0);
        expect(candle.close, 0);
        expect(candle.volume, 0);
      });
    });
  });
}
