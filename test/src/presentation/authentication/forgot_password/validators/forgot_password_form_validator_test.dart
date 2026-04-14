import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_state.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/validators/forgot_password_form_validator.dart';

void main() {
  const validator = ForgotPasswordFormValidator(
    emailValidation: EmailValidation(),
  );

  group('ForgotPasswordFormValidator', () {
    test('sets emailFailure when email is empty', () {
      const input = ForgotPasswordState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNotNull);
    });

    test('sets emailFailure when email is invalid', () {
      const input = ForgotPasswordState(email: 'notanemail');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNotNull);
    });

    test('returns isValid true and clears failure when email is valid', () {
      const input = ForgotPasswordState(email: 'jane@trocado.app');

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.emailFailure, isNull);
    });
  });
}
