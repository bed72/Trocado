import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart';
import 'package:trocado/src/presentation/ui/profile/delete/validators/profile_delete_form_validator.dart';

void main() {
  const validator = ProfileDeleteFormValidator(
    passwordValidation: PasswordValidation(),
  );

  group('ProfileDeleteFormValidator', () {
    test('sets passwordFailure when password is empty', () {
      const input = ProfileDeleteState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.passwordFailure, 'Senha obrigatória');
    });

    test('sets passwordFailure when password is too short', () {
      const input = ProfileDeleteState(password: 'abc');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.passwordFailure, 'Senha deve ter ao menos 8 caracteres');
    });

    test('returns isValid true and clears passwordFailure when valid', () {
      const input = ProfileDeleteState(
        password: 'MyPassword!456',
        passwordFailure: 'Senha obrigatória',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.passwordFailure, isNull);
    });
  });
}
