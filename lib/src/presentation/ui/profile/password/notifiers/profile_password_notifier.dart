import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart';

part 'profile_password_notifier.g.dart';

@Riverpod()
final class ProfilePasswordNotifier extends _$ProfilePasswordNotifier {
  late IUserRepository _repository;
  late ProfilePasswordFormValidator _validator;

  @override
  Future<ProfilePasswordState> build() async {
    _repository = ref.watch(userRepositoryProvider);
    _validator = ref.watch(profilePasswordFormValidatorProvider);

    return const ProfilePasswordState();
  }

  void dispatch(ProfilePasswordIntent intent) => switch (intent) {
    CurrentPasswordChanged(:final value) => state = AsyncData(
      state.value!.copyWith(
        currentPassword: value,
        clearCurrentPasswordFailure: true,
      ),
    ),
    NewPasswordChanged(:final value) => state = AsyncData(
      state.value!.copyWith(newPassword: value, clearNewPasswordFailure: true),
    ),
    CurrentPasswordVisibilityToggled() => state = AsyncData(
      state.value!.copyWith(
        obscureCurrentPassword: !state.value!.obscureCurrentPassword,
      ),
    ),
    NewPasswordVisibilityToggled() => state = AsyncData(
      state.value!.copyWith(
        obscureNewPassword: !state.value!.obscureNewPassword,
      ),
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (state: validated, :isValid) = _validator(state.value!);
    state = AsyncData(validated);

    if (!isValid) return;
    if (validated.status == .loading) return;

    state = AsyncData(validated.copyWith(status: .loading));

    final data = await _repository.updatePassword(
      newPassword: validated.newPassword,
      currentPassword: validated.currentPassword,
    );

    data.fold(
      (failure) => state = AsyncData(
        state.value!.copyWith(status: .failure, message: failure.message),
      ),
      (_) {
        ref.invalidate(userProvider);
        state = AsyncData(state.value!.copyWith(status: .success));
      },
    );
  }
}
