import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Remote server failure.', this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage failure.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failure.']);
}

class AuthFailure extends Failure {
  final String? code;
  const AuthFailure([super.message = 'Authentication failure.', this.code]);

  @override
  List<Object?> get props => [message, code];
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failure.']);
}
