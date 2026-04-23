import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart';
import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/notifiers/password_reset_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/validators/password_reset_confirm_form_validator.dart';

part 'password_reset_confirm_notifier.g.dart';

@riverpod
final class PasswordResetConfirmNotifier
    extends _$PasswordResetConfirmNotifier {
  late IAuthenticationRepository _repository;
  late PasswordResetConfirmFormValidator _validator;

  @override
  PasswordResetConfirmState build({
    required String uid,
    required String token,
  }) {
    _repository = ref.watch(authenticationRepositoryProvider);
    _validator = ref.watch(passwordResetConfirmFormValidatorProvider);

    return const PasswordResetConfirmState();
  }

  void dispatch(PasswordResetConfirmIntent intent) => switch (intent) {
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

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: .loading);

    final data = await _repository.confirmPasswordReset(
      uid: uid,
      token: token,
      newPassword: this.state.newPassword,
    );

    data.fold(
      (failure) => this.state = this.state.copyWith(
        status: .failure,
        message: failure.message,
      ),
      (_) => this.state = this.state.copyWith(status: .success),
    );
  }
}
