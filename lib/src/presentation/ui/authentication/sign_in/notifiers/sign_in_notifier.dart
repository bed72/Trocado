import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/validators/sign_in_form_validator.dart';

part 'sign_in_notifier.g.dart';

@riverpod
final class SignInNotifier extends _$SignInNotifier {
  late SignInFormValidator _validator;
  late IAuthenticationRepository _repository;

  @override
  SignInState build() {
    _validator = ref.watch(signInFormValidatorProvider);
    _repository = ref.watch(authenticationRepositoryProvider);

    return const SignInState();
  }

  void dispatch(SignInIntent intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(
      email: value,
      clearEmailFailure: true,
    ),
    PasswordChanged(:final value) => state = state.copyWith(
      password: value,
      clearPasswordFailure: true,
    ),
    PasswordVisibilityToggled() => state = state.copyWith(
      obscurePassword: !state.obscurePassword,
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: .loading);

    final data = await _repository.signIn(
      email: this.state.email,
      password: this.state.password,
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
