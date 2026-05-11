import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart';

void main() {
  const validator = ProfilePasswordFormValidator(
    passwordValidation: PasswordValidation(),
  );

  group('ProfilePasswordFormValidator', () {
    test('sets currentPasswordFailure when current password is empty', () {
      const input = ProfilePasswordState(newPassword: 'NewSecure!456');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNull);
      expect(state.currentPasswordFailure, isNotNull);
    });

    test('sets newPasswordFailure when new password is empty', () {
      const input = ProfilePasswordState(currentPassword: 'OldPassword!123');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
      expect(state.currentPasswordFailure, isNull);
    });

    test('sets newPasswordFailure when new password is too short', () {
      const input = ProfilePasswordState(
        newPassword: 'abc123',
        currentPassword: 'OldPassword!123',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
      expect(state.currentPasswordFailure, isNull);
    });

    test('sets both failures when both passwords are invalid', () {
      const input = ProfilePasswordState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.newPasswordFailure, isNotNull);
      expect(state.currentPasswordFailure, isNotNull);
    });

    test('returns isValid true when both passwords are valid', () {
      const input = ProfilePasswordState(
        newPassword: 'NewSecure!456',
        currentPassword: 'OldPassword!123',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.newPasswordFailure, isNull);
      expect(state.currentPasswordFailure, isNull);
    });
  });
}
