import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart';
import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_intent.dart';
import 'package:trocado/src/presentation/ui/profile/delete/validators/profile_delete_form_validator.dart';

part 'profile_delete_notifier.g.dart';

@Riverpod()
final class ProfileDeleteNotifier extends _$ProfileDeleteNotifier {
  late IUserRepository _repository;
  late ProfileDeleteFormValidator _validator;

  @override
  ProfileDeleteState build() {
    _repository = ref.watch(userRepositoryProvider);
    _validator = ref.watch(profileDeleteFormValidatorProvider);

    return const ProfileDeleteState();
  }

  void dispatch(ProfileDeleteIntent intent) => switch (intent) {
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

    final data = await _repository.delete(password: this.state.password);

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
  }
}
