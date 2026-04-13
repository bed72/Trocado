import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_events.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

part '../sign_in_notifier.g.dart';

@riverpod
final class SignInNotifier extends _$SignInNotifier {
  @override
  SignInState build() => const SignInState();

  void dispatch(SignInEvents intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(email: value),
    PasswordChanged(:final value) => state = state.copyWith(password: value),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    state = state.copyWith(status: .loading);

    final data = await ref
        .read(authenticationRepositoryProvider)
        .signIn(email: state.email, password: state.password);

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) => state = state.copyWith(status: .success),
    );
  }
}
