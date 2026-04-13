import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

void main() {
  const validation = PasswordValidation();

  group('PasswordValidation', () {
    test('returns Invalid when password is empty', () {
      final data = validation('');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'Senha obrigatória');
    });

    test('returns Invalid when password is shorter than 8 characters', () {
      final data = validation('1234567');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'Senha deve ter ao menos 8 caracteres');
    });

    test('returns Valid when password has exactly 8 characters', () {
      final data = validation('12345678');

      expect(data, isA<Valid<String>>());
    });

    test('returns Valid when password is longer than 8 characters', () {
      final data = validation('secret123');

      expect(data, isA<Valid<String>>());
    });
  });
}
