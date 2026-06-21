import 'package:flutter_test/flutter_test.dart';
import 'package:taug/core/errors/result.dart';

void main() {
  group('Result<T>', () {
    // -----------------------------------------------------------------------
    // Result.success
    // -----------------------------------------------------------------------
    group('Result.success', () {
      test('creates a Success instance with the given data', () {
        const result = Result<String>.success('hello');

        expect(result, isA<Success<String>>());
        expect(result.data, 'hello');
      });

      test('holds int data correctly', () {
        const result = Result<int>.success(42);

        expect(result, isA<Success<int>>());
        expect(result.data, 42);
      });

      test('holds null data when T is nullable', () {
        const result = Result<String?>.success(null);

        expect(result, isA<Success<String?>>());
        expect(result.data, isNull);
      });

      test('holds complex object data', () {
        final map = {'key': 'value', 'count': 3};
        final result = Result<Map<String, Object>>.success(map);

        expect(result.data, same(map));
      });
    });

    // -----------------------------------------------------------------------
    // Result.failure
    // -----------------------------------------------------------------------
    group('Result.failure', () {
      test('creates a ResultFailure instance with the given error', () {
        const result = Result<String>.failure('something went wrong');

        expect(result, isA<ResultFailure<String>>());
        expect(result.error, 'something went wrong');
      });

      test('holds an Exception as error', () {
        final exception = Exception('network timeout');
        final result = Result<int>.failure(exception);

        expect(result.error, same(exception));
      });

      test('holds an Error object as error', () {
        final error = StateError('bad state');
        final result = Result<double>.failure(error);

        expect(result.error, same(error));
      });
    });

    // -----------------------------------------------------------------------
    // isSuccess / isFailure getters
    // -----------------------------------------------------------------------
    group('isSuccess / isFailure', () {
      test('isSuccess returns true for Success', () {
        const result = Result<int>.success(1);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('isFailure returns true for ResultFailure', () {
        const result = Result<int>.failure('err');

        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('exactly one of isSuccess/isFailure is always true', () {
        const success = Result<String>.success('ok');
        const failure = Result<String>.failure('nope');

        expect(success.isSuccess ^ success.isFailure, isTrue);
        expect(failure.isSuccess ^ failure.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // data getter
    // -----------------------------------------------------------------------
    group('data getter', () {
      test('returns the wrapped value on Success', () {
        const result = Result<String>.success('payload');

        expect(result.data, 'payload');
      });

      test('returns null on ResultFailure', () {
        const result = Result<String>.failure('err');

        expect(result.data, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // error getter
    // -----------------------------------------------------------------------
    group('error getter', () {
      test('returns the error object on ResultFailure', () {
        const result = Result<int>.failure('boom');

        expect(result.error, 'boom');
      });

      test('throws StateError on Success', () {
        const result = Result<int>.success(1);

        expect(
          () => result.error,
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            'No error in success',
          )),
        );
      });
    });

    // -----------------------------------------------------------------------
    // map
    // -----------------------------------------------------------------------
    group('map()', () {
      test('transforms data when Success', () {
        const result = Result<int>.success(5);
        final mapped = result.map((n) => n.toString());

        expect(mapped, isA<Success<String>>());
        expect(mapped.data, '5');
      });

      test('propagates failure without calling transform', () {
        const result = Result<int>.failure('err');
        final mapped = result.map((n) => n * 2);

        expect(mapped.isFailure, isTrue);
        expect(mapped.error, 'err');
      });
    });

    // -----------------------------------------------------------------------
    // flatMap
    // -----------------------------------------------------------------------
    group('flatMap()', () {
      test('chains transform when Success', () {
        const result = Result<int>.success(10);
        final chained = result.flatMap(
          (n) => Result<String>.success('value=$n'),
        );

        expect(chained, isA<Success<String>>());
        expect(chained.data, 'value=10');
      });

      test('chains to a failure when transform returns failure', () {
        const result = Result<int>.success(10);
        final chained = result.flatMap(
          (n) => const Result<String>.failure('transform failed'),
        );

        expect(chained, isA<ResultFailure<String>>());
        expect(chained.error, 'transform failed');
      });

      test('propagates failure without calling transform', () {
        const result = Result<int>.failure('original err');
        final chained = result.flatMap(
          (n) => Result<String>.success('should not reach'),
        );

        expect(chained, isA<ResultFailure<String>>());
        expect(chained.error, 'original err');
      });
    });

    // -----------------------------------------------------------------------
    // const constructors
    // -----------------------------------------------------------------------
    group('const construction', () {
      test('Success can be constructed as const', () {
        const a = Success<int>(42);
        const b = Success<int>(42);

        expect(identical(a, b), isTrue);
      });

      test('ResultFailure can be constructed as const', () {
        const a = ResultFailure<String>('err');
        const b = ResultFailure<String>('err');

        expect(identical(a, b), isTrue);
      });
    });
  });
}
