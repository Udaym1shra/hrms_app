// Error handling and failures
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure({
    required this.message,
    this.code,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class LocationFailure extends Failure {
  const LocationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
