import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/ui/couple/scan/validators/invite_code_validation.dart';

void main() {
  const validation = InviteCodeValidation();

  group('InviteCodeValidation', () {
    test('returns Valid for a 6-character uppercase code in alphabet', () {
      final data = validation('AB3K7N');

      expect(data, isA<Valid<String>>());
      expect((data as Valid<String>).value, 'AB3K7N');
    });

    test('trims and uppercases before validating', () {
      final data = validation('  ab3k7n  ');

      expect(data, isA<Valid<String>>());
      expect((data as Valid<String>).value, 'AB3K7N');
    });

    test('returns Invalid when empty', () {
      final data = validation('');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid<String>).message, 'Código obrigatório');
    });

    test('returns Invalid when only whitespace', () {
      final data = validation('   ');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid<String>).message, 'Código obrigatório');
    });

    test('returns Invalid when shorter than 6', () {
      final data = validation('AB3');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid<String>).message, 'Código deve ter 6 caracteres');
    });

    test('returns Invalid when longer than 6', () {
      final data = validation('AB3K7NQ');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid<String>).message, 'Código deve ter 6 caracteres');
    });

    test('returns Invalid when contains ambiguous chars (I, O, 0, 1)', () {
      for (final code in ['ABCDIE', 'ABCD0E', 'ABCD1E', 'OBCDEF']) {
        final data = validation(code);
        expect(data, isA<Invalid<String>>(), reason: 'failed for $code');
        expect(
          (data as Invalid<String>).message,
          'Código inválido',
          reason: 'failed for $code',
        );
      }
    });

    test('returns Invalid when contains special chars', () {
      final data = validation('AB-3K7');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid<String>).message, 'Código inválido');
    });
  });
}
