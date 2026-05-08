import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_state.dart';

final class ProfilePurgeFormValidator {
  final PasswordValidation _passwordValidation;

  const ProfilePurgeFormValidator({
    required PasswordValidation passwordValidation,
  }) : _passwordValidation = passwordValidation;

  ({ProfilePurgeState state, bool isValid}) call(ProfilePurgeState state) {
    final password = _passwordValidation(state.password);
    final isValid = password is Valid;

    final validated = state.copyWith(
      passwordFailure: switch (password) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearPasswordFailure: password is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
