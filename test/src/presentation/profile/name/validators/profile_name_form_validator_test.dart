import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/ui/profile/name/validators/name_validation.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';
import 'package:trocado/src/presentation/ui/profile/name/validators/profile_name_form_validator.dart';

void main() {
  const validator = ProfileNameFormValidator(
    nameValidation: NameValidation(),
  );

  group('ProfileNameFormValidator', () {
    test('sets nameFailure when name is empty', () {
      const input = ProfileNameState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.nameFailure, 'Nome obrigatório');
    });

    test('sets nameFailure when name exceeds 128 characters', () {
      final input = ProfileNameState(name: 'a' * 129);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.nameFailure, 'Nome deve ter no máximo 128 caracteres');
    });

    test('returns isValid true and clears failure when name is valid', () {
      const input = ProfileNameState(
        name: 'Kevin',
        nameFailure: 'Nome obrigatório',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.nameFailure, isNull);
    });
  });
}
