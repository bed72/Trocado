import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_state.dart';
import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_intent.dart';
import 'package:trocado/src/presentation/ui/profile/purge/validators/profile_purge_form_validator.dart';

part 'profile_purge_notifier.g.dart';

@riverpod
final class ProfilePurgeNotifier extends _$ProfilePurgeNotifier {
  late IUserRepository _repository;
  late ProfilePurgeFormValidator _validator;

  @override
  ProfilePurgeState build() {
    _repository = ref.watch(userRepositoryProvider);
    _validator = ref.watch(profilePurgeFormValidatorProvider);

    return const ProfilePurgeState();
  }

  void dispatch(ProfilePurgeIntent intent) => switch (intent) {
    PasswordChanged(:final value) => state = state.copyWith(
      password: value,
      clearPasswordFailure: true,
    ),
    PasswordVisibilityToggled() => state = state.copyWith(
      obscurePassword: !state.obscurePassword,
    ),
    ValidatePressed() => _validate(),
    SubmitPressed() => _submit(),
  };

  void _validate() {
    final (state: validated, isValid: _) = _validator(state);
    state = validated;
  }

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;
    if (this.state.status == .loading) return;

    this.state = this.state.copyWith(status: .loading);

    if (ref.read(userProvider) case AsyncData(:final value)) {
      final data = await _repository.purge(
        email: value.email,
        password: this.state.password,
      );

      data.fold(
        (failure) =>
            this.state = this.state.copyWith(
              status: .failure,
              message: failure.message,
            ),
        (_) {
          ref.invalidate(userProvider);
          this.state = this.state.copyWith(status: .success);
        },
      );
      return;
    }

    this.state = this.state.copyWith(
      status: .failure,
      message: 'Não foi possível identificar o usuário.',
    );
  }
}
