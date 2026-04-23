import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_state.dart';

final class SignInFormValidator {
  final EmailValidation _emailValidation;
  final PasswordValidation _passwordValidation;

  const SignInFormValidator({
    required EmailValidation emailValidation,
    required PasswordValidation passwordValidation,
  }) : _emailValidation = emailValidation,
       _passwordValidation = passwordValidation;

  ({SignInState state, bool isValid}) call(SignInState state) {
    final email = _emailValidation(state.email);
    final password = _passwordValidation(state.password);

    final isValid = email is Valid && password is Valid;

    final validated = state.copyWith(
      emailFailure: switch (email) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      passwordFailure: switch (password) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearEmailFailure: email is Valid,
      clearPasswordFailure: password is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
