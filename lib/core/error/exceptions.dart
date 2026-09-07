abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection available.']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException([super.message = 'A server error occurred.', this.statusCode]);

  @override
  String toString() => statusCode != null ? '$message (Code: $statusCode)' : message;
}

class CacheException extends AppException {
  const CacheException([super.message = 'A local storage error occurred.']);
}

class AuthException extends AppException {
  final String? code;
  const AuthException([super.message = 'Authentication failed.', this.code]);

  @override
  String toString() => code != null ? '$message ($code)' : message;
}
