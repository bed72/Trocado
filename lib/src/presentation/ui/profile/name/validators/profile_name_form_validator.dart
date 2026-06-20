import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/ui/profile/name/validators/name_validation.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';

final class ProfileNameFormValidator {
  final NameValidation _nameValidation;

  const ProfileNameFormValidator({required this._nameValidation});

  ({ProfileNameState state, bool isValid}) call(ProfileNameState state) {
    final name = _nameValidation(state.name);

    final validated = state.copyWith(
      nameFailure: switch (name) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearNameFailure: name is Valid,
    );

    return (state: validated, isValid: name is Valid);
  }
}
