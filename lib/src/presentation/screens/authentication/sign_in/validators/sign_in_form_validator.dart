import 'package:trocado/src/domain/validators/validation.dart';
import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';

final class SignInFormValidator {
  final EmailValidation _emailValidation;
  final PasswordValidation _passwordValidation;

  const SignInFormValidator({
    required EmailValidation emailValidation,
    required PasswordValidation passwordValidation,
  }) : _emailValidation = emailValidation,
       _passwordValidation = passwordValidation;

  ({SignInState state, bool isValid}) call(SignInState state) {
    final emailResult = _emailValidation(state.email);
    final passwordResult = _passwordValidation(state.password);

    final isValid = emailResult is Valid && passwordResult is Valid;

    final validated = state.copyWith(
      emailFailure: switch (emailResult) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      passwordFailure: switch (passwordResult) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearEmailFailure: emailResult is Valid,
      clearPasswordFailure: passwordResult is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
