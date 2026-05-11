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
    final newPassword = _passwordValidation(state.newPassword);
    final currentPassword = _passwordValidation(state.currentPassword);

    final isValid = currentPassword is Valid && newPassword is Valid;

    final validated = state.copyWith(
      currentPasswordFailure: switch (currentPassword) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      newPasswordFailure: switch (newPassword) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearCurrentPasswordFailure: currentPassword is Valid,
      clearNewPasswordFailure: newPassword is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
