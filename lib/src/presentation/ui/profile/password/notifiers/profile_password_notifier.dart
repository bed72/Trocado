import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart';

part 'profile_password_notifier.g.dart';

@riverpod
final class ProfilePasswordNotifier extends _$ProfilePasswordNotifier {
  late ProfilePasswordFormValidator _validator;

  @override
  ProfilePasswordState build() {
    _validator = ref.watch(profilePasswordFormValidatorProvider);

    return const ProfilePasswordState();
  }

  void dispatch(ProfilePasswordIntent intent) => switch (intent) {
    NewPasswordChanged(:final value) => state = state.copyWith(
      newPassword: value,
      clearNewPasswordFailure: true,
    ),
    ConfirmPasswordChanged(:final value) => state = state.copyWith(
      confirmPassword: value,
      clearConfirmPasswordFailure: true,
    ),
    NewPasswordVisibilityToggled() => state = state.copyWith(
      obscureNewPassword: !state.obscureNewPassword,
    ),
    ConfirmPasswordVisibilityToggled() => state = state.copyWith(
      obscureConfirmPassword: !state.obscureConfirmPassword,
    ),
    SubmitPressed() => _submit(),
  };

  void _submit() {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;
    // TODO Parte 6: chamar repository.updatePassword(password: this.state.newPassword)
  }
}
