import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';

final class ProfilePasswordFormValidator {
  final PasswordValidation _passwordValidation;

  const ProfilePasswordFormValidator({
    required PasswordValidation passwordValidation,
  }) : _passwordValidation = passwordValidation;

  ({ProfilePasswordState state, bool isValid}) call(
    ProfilePasswordState state,
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
      confirmPasswordFailure: confirmFailure,
      clearNewPasswordFailure: password is Valid,
      clearConfirmPasswordFailure: confirmFailure == null,
    );

    return (state: validated, isValid: isValid);
  }
}
