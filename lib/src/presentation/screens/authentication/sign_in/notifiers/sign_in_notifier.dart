import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_intent.dart';

part 'sign_in_notifier.g.dart';

@riverpod
final class SignInNotifier extends _$SignInNotifier {
  late IAuthenticationRepository _repository;

  @override
  SignInState build() {
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
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    if (!_validate()) return;

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

  bool _validate() {
    final emailFailure = _validateEmail(state.email);
    final passwordFailure = _validatePassword(state.password);

    if (emailFailure != null || passwordFailure != null) {
      state = state.copyWith(
        emailFailure: emailFailure,
        passwordFailure: passwordFailure,
      );
      return false;
    }
    return true;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'E-mail obrigatório';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return 'E-mail inválido';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Senha obrigatória';
    if (password.length < 8) return 'Senha deve ter ao menos 8 caracteres';
    return null;
  }
}
