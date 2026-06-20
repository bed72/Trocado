import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';

import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_state.dart';

final class ForgotPasswordFormValidator {
  final EmailValidation _emailValidation;

  const ForgotPasswordFormValidator({required this._emailValidation});

  ({ForgotPasswordState state, bool isValid}) call(ForgotPasswordState state) {
    final email = _emailValidation(state.email);

    final isValid = email is Valid;

    final validated = state.copyWith(
      emailFailure: switch (email) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearEmailFailure: email is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
