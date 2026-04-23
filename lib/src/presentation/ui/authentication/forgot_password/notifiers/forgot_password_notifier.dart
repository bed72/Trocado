import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_state.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/validators/forgot_password_form_validator.dart';

part 'forgot_password_notifier.g.dart';

@riverpod
final class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  late IAuthenticationRepository _repository;
  late ForgotPasswordFormValidator _validator;

  @override
  ForgotPasswordState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    _validator = ref.watch(forgotPasswordFormValidatorProvider);

    return const ForgotPasswordState();
  }

  void dispatch(ForgotPasswordIntent intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(
      email: value,
      clearEmailFailure: true,
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: .loading);

    final data = await _repository.requestPasswordReset(
      email: this.state.email,
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
