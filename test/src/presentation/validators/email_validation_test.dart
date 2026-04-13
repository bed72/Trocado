import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';

void main() {
  const validation = EmailValidation();

  group('EmailValidation', () {
    test('returns Invalid when email is empty', () {
      final data = validation('');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'E-mail obrigatório');
    });

    test('returns Invalid when email has no @', () {
      final data = validation('notanemail');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'E-mail inválido');
    });

    test('returns Invalid when domain has no dot', () {
      final data = validation('user@domain');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'E-mail inválido');
    });

    test('returns Valid with trimmed value for valid email', () {
      final data = validation('  jane@trocado.app  ');

      expect(data, isA<Valid<String>>());
      expect((data as Valid).value, 'jane@trocado.app');
    });

    test('returns Valid for standard email format', () {
      final data = validation('jane@trocado.app');

      expect(data, isA<Valid<String>>());
    });
  });
}
