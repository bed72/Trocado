import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/validators/terms_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_up/notifiers/sign_up_state.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/validators/sign_up_form_validator.dart';

void main() {
  const validator = SignUpFormValidator(
    emailValidation: EmailValidation(),
    termsValidation: TermsValidation(),
    passwordValidation: PasswordValidation(),
  );

  group('SignUpFormValidator', () {
    test('sets all failures when all fields are invalid', () {
      const input = SignUpState();

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNotNull);
      expect(state.termsFailure, isNotNull);
      expect(state.passwordFailure, isNotNull);
    });

    test('sets only emailFailure when email is invalid', () {
      const input = SignUpState(password: 'secret123', termsAccepted: true);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.termsFailure, isNull);
      expect(state.emailFailure, isNotNull);
      expect(state.passwordFailure, isNull);
    });

    test('sets only passwordFailure when password is invalid', () {
      const input = SignUpState(email: 'jane@trocado.app', termsAccepted: true);

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNull);
      expect(state.termsFailure, isNull);
      expect(state.passwordFailure, isNotNull);
    });

    test('sets only termsFailure when terms not accepted', () {
      const input = SignUpState(
        password: 'secret123',
        email: 'jane@trocado.app',
      );

      final (:state, :isValid) = validator(input);

      expect(isValid, isFalse);
      expect(state.emailFailure, isNull);
      expect(state.passwordFailure, isNull);
      expect(state.termsFailure, isNotNull);
    });

    test(
      'returns isValid true and clears all failures when all fields are valid',
      () {
        const input = SignUpState(
          termsAccepted: true,
          password: 'secret123',
          email: 'jane@trocado.app',
        );

        final (:state, :isValid) = validator(input);

        expect(isValid, isTrue);
        expect(state.emailFailure, isNull);
        expect(state.termsFailure, isNull);
        expect(state.passwordFailure, isNull);
      },
    );
  });
}
