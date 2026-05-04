import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart';

void main() {
  const validator = ProfilePasswordFormValidator(
    passwordValidation: PasswordValidation(),
  );

  group('ProfilePasswordFormValidator', () {
    test('sets newPasswordFailure when password is empty', () {
      const input = ProfilePasswordState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
    });

    test('sets newPasswordFailure when password is too short', () {
      const input = ProfilePasswordState(newPassword: 'abc123');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
    });

    test('sets confirmPasswordFailure when passwords do not match', () {
      const input = ProfilePasswordState(
        newPassword: 'NewSecure!456',
        confirmPassword: 'Different!789',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNull);
      expect(state.confirmPasswordFailure, 'As senhas não coincidem');
    });

    test('returns isValid true when passwords are valid and match', () {
      const input = ProfilePasswordState(
        newPassword: 'NewSecure!456',
        confirmPassword: 'NewSecure!456',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.newPasswordFailure, isNull);
      expect(state.confirmPasswordFailure, isNull);
    });
  });
}
