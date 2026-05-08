import 'package:flutter_test/flutter_test.dart';
import 'package:naissance/domain/exceptions.dart';

void main() {
  group('Exceptions Domain Tests', () {
    test('ValidationException a le bon code et message', () {
      final ex = ValidationException(message: 'Données invalides');
      expect(ex.code, 'VALIDATION_ERROR');
      expect(ex.message, 'Données invalides');
      expect(ex.toString(), 'AppException[VALIDATION_ERROR]: Données invalides');
    });

    test('NetworkException a le bon code', () {
      final ex = NetworkException(message: 'Pas de réseau');
      expect(ex.code, 'NETWORK_ERROR');
    });

    test('AuthException contient une erreur originale', () {
      final innerError = FormatException('Bad format');
      final ex = AuthException(message: 'Token invalide', originalError: innerError);
      
      expect(ex.code, 'AUTH_ERROR');
      expect(ex.originalError, isA<FormatException>());
    });
  });
}
