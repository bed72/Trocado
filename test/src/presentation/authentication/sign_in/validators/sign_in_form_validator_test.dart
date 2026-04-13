import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/validators/sign_in_form_validator.dart';

void main() {
  const validator = SignInFormValidator(
    emailValidation: EmailValidation(),
    passwordValidation: PasswordValidation(),
  );

  group('SignInFormValidator', () {
    test('sets both failures when both fields are invalid', () {
      const input = SignInState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNotNull);
      expect(state.passwordFailure, isNotNull);
    });

    test('sets only emailFailure when email is invalid and password is valid', () {
      const input = SignInState(password: 'secret123');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNotNull);
      expect(state.passwordFailure, isNull);
    });

    test('sets only passwordFailure when password is invalid and email is valid', () {
      const input = SignInState(email: 'jane@trocado.app');

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNull);
      expect(state.passwordFailure, isNotNull);
    });

    test('returns isValid true and clears failures when both fields are valid', () {
      const input = SignInState(
        email: 'jane@trocado.app',
        password: 'secret123',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isTrue);
      expect(state.emailFailure, isNull);
      expect(state.passwordFailure, isNull);
    });
  });
}
