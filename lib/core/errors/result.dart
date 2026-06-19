sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Object error) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  T? get data => switch (this) {
    Success<T>(:final data) => data,
    ResultFailure<T>() => null,
  };

  Object get error => switch (this) {
    Success<T>() => throw StateError('No error in success'),
    ResultFailure<T>(:final error) => error,
  };

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      ResultFailure<T>(:final error) => Result.failure(error),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      ResultFailure<T>(:final error) => Result.failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);
}

final class ResultFailure<T> extends Result<T> {
  @override
  final Object error;

  const ResultFailure(this.error);
}
