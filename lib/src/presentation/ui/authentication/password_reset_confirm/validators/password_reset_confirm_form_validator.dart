import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart';

final class PasswordResetConfirmFormValidator {
  final PasswordValidation _passwordValidation;

  const PasswordResetConfirmFormValidator({
    required PasswordValidation passwordValidation,
  }) : _passwordValidation = passwordValidation;

  ({PasswordResetConfirmState state, bool isValid}) call(
    PasswordResetConfirmState state,
  ) {
    final password = _passwordValidation(state.newPassword);

    final confirmFailure = switch (password) {
      Invalid() => null,
      Valid() when state.confirmPassword != state.newPassword =>
        'As senhas não coincidem',
      Valid() => null,
    };

    final isValid = password is Valid && confirmFailure == null;

    final validated = state.copyWith(
      newPasswordFailure: switch (password) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearNewPasswordFailure: password is Valid,
      confirmPasswordFailure: confirmFailure,
      clearConfirmPasswordFailure: confirmFailure == null,
    );

    return (state: validated, isValid: isValid);
  }
}
