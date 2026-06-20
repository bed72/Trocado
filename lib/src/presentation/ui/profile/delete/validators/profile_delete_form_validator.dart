import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart';

final class ProfileDeleteFormValidator {
  final PasswordValidation _passwordValidation;

  const ProfileDeleteFormValidator({required this._passwordValidation});

  ({ProfileDeleteState state, bool isValid}) call(ProfileDeleteState state) {
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
