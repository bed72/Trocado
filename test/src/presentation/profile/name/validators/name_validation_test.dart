import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/ui/profile/name/validators/name_validation.dart';

void main() {
  const validation = NameValidation();

  group('NameValidation', () {
    test('returns Invalid when name is empty', () {
      final data = validation('');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'Nome obrigatório');
    });

    test('returns Invalid when name is whitespace only', () {
      final data = validation('   ');

      expect(data, isA<Invalid<String>>());
      expect((data as Invalid).message, 'Nome obrigatório');
    });

    test('returns Invalid when name is longer than 128 characters', () {
      final data = validation('a' * 129);

      expect(data, isA<Invalid<String>>());
      expect(
        (data as Invalid).message,
        'Nome deve ter no máximo 128 caracteres',
      );
    });

    test('returns Valid when name has exactly 1 character', () {
      final data = validation('A');

      expect(data, isA<Valid<String>>());
      expect((data as Valid).value, 'A');
    });

    test('returns Valid when name has exactly 128 characters', () {
      final input = 'a' * 128;
      final data = validation(input);

      expect(data, isA<Valid<String>>());
      expect((data as Valid).value, input);
    });

    test('returns Valid with trimmed value when name has surrounding spaces', () {
      final data = validation('  Kevin  ');

      expect(data, isA<Valid<String>>());
      expect((data as Valid).value, 'Kevin');
    });
  });
}
