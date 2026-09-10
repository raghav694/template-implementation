class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Network connection failed']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  const ServerException([this.message = 'Server error occurred']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}
