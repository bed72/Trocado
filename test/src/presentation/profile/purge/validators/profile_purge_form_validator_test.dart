import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_state.dart';
import 'package:trocado/src/presentation/ui/profile/purge/validators/profile_purge_form_validator.dart';

void main() {
  const validator = ProfilePurgeFormValidator(
    passwordValidation: PasswordValidation(),
  );

  group('ProfilePurgeFormValidator', () {
    test('sets passwordFailure when password is empty', () {
      const input = ProfilePurgeState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.passwordFailure, 'Senha obrigatória');
    });

    test('sets passwordFailure when password is too short', () {
      const input = ProfilePurgeState(password: 'abc');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.passwordFailure, 'Senha deve ter ao menos 8 caracteres');
    });

    test('returns isValid true and clears passwordFailure when valid', () {
      const input = ProfilePurgeState(
        password: 'MyPassword!456',
        passwordFailure: 'Senha obrigatória',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.passwordFailure, isNull);
    });
  });
}
