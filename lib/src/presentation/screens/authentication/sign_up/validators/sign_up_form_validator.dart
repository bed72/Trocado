import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/validators/terms_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_state.dart';

final class SignUpFormValidator {
  final EmailValidation _emailValidation;
  final TermsValidation _termsValidation;
  final PasswordValidation _passwordValidation;

  const SignUpFormValidator({
    required EmailValidation emailValidation,
    required TermsValidation termsValidation,
    required PasswordValidation passwordValidation,
  }) : _emailValidation = emailValidation,
       _termsValidation = termsValidation,
       _passwordValidation = passwordValidation;

  ({SignUpState state, bool isValid}) call(SignUpState state) {
    final email = _emailValidation(state.email);
    final terms = _termsValidation(state.termsAccepted);
    final password = _passwordValidation(state.password);

    final isValid = email is Valid && password is Valid && terms is Valid;

    final validated = state.copyWith(
      emailFailure: switch (email) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      passwordFailure: switch (password) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      termsFailure: switch (terms) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearEmailFailure: email is Valid,
      clearTermsFailure: terms is Valid,
      clearPasswordFailure: password is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
