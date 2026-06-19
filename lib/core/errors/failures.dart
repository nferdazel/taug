import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

final class ServerFailure extends Failure {
  final String message;
  final int? statusCode;

  const ServerFailure({required this.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

final class CacheFailure extends Failure {
  final String message;

  const CacheFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class AuthFailure extends Failure {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class DataSourceFailure extends Failure {
  final String message;
  final String source;

  const DataSourceFailure({required this.message, required this.source});

  @override
  List<Object> get props => [message, source];
}
