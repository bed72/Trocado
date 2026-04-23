import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart';
import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/validators/password_reset_confirm_form_validator.dart';

void main() {
  const validator = PasswordResetConfirmFormValidator(
    passwordValidation: PasswordValidation(),
  );

  group('PasswordResetConfirmFormValidator', () {
    test('sets newPasswordFailure when password is empty', () {
      const input = PasswordResetConfirmState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
    });

    test('sets newPasswordFailure when password is too short', () {
      const input = PasswordResetConfirmState(newPassword: 'abc123');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
    });

    test('sets confirmPasswordFailure when passwords do not match', () {
      const input = PasswordResetConfirmState(
        newPassword: 'NewSecure!456',
        confirmPassword: 'Different!789',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.confirmPasswordFailure, isNotNull);
      expect(state.newPasswordFailure, isNull);
    });

    test('returns isValid true when passwords are valid and match', () {
      const input = PasswordResetConfirmState(
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
