import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_up/notifiers/sign_up_state.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/notifiers/sign_up_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/validators/sign_up_form_validator.dart';

part 'sign_up_notifier.g.dart';

@Riverpod()
final class SignUpNotifier extends _$SignUpNotifier {
  late SignUpFormValidator _validator;
  late INotificationRepository _notificationRepository;
  late IAuthenticationRepository _authenticationRepository;

  @override
  SignUpState build() {
    _validator = ref.watch(signUpFormValidatorProvider);
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _authenticationRepository = ref.watch(authenticationRepositoryProvider);

    return const SignUpState();
  }

  void dispatch(SignUpIntent intent) => switch (intent) {
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
    TermsToggled(:final value) => state = state.copyWith(
      termsAccepted: value,
      clearTermsFailure: true,
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: .loading);

    final data = await _authenticationRepository.signUp(
      email: this.state.email,
      password: this.state.password,
    );

    data.fold(
      (failure) => this.state = this.state.copyWith(
        status: .failure,
        message: failure.message,
      ),
      (_) {
        unawaited(_notificationRepository.registerToken());
        this.state = this.state.copyWith(status: .success);
      },
    );
  }
}
