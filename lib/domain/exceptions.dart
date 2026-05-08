class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException[$code]: $message';
}

class ValidationException extends AppException {
  ValidationException({required super.message, super.originalError}) 
    : super(code: 'VALIDATION_ERROR');
}

class NetworkException extends AppException {
  NetworkException({required super.message, super.originalError}) 
    : super(code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException({required super.message, super.originalError}) 
    : super(code: 'AUTH_ERROR');
}
