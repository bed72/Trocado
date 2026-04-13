import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_events.dart';

part 'sign_in_notifier.g.dart';

@riverpod
final class SignInNotifier extends _$SignInNotifier {
  late IAuthenticationRepository _repository;

  @override
  SignInState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    return const SignInState();
  }

  void dispatch(SignInEvents events) => switch (events) {
    EmailChanged(:final value) => state = state.copyWith(email: value),
    PasswordChanged(:final value) => state = state.copyWith(password: value),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    state = state.copyWith(status: .loading);

    final data = await _repository.signIn(
      email: state.email,
      password: state.password,
    );

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) => state = state.copyWith(status: .success),
    );
  }
}
