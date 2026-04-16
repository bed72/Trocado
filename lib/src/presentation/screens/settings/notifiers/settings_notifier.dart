import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/settings/notifiers/settings_state.dart';
import 'package:trocado/src/presentation/screens/settings/notifiers/settings_intent.dart';

part 'settings_notifier.g.dart';

@riverpod
final class SettingsNotifier extends _$SettingsNotifier {
  late IAuthenticationRepository _repository;

  @override
  SettingsState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    return const SettingsState();
  }

  void dispatch(SettingsIntent intent) => switch (intent) {
    LogoutPressed() => _logout(),
  };

  Future<void> _logout() async {
    if (state.status == .loading) return;

    state = state.copyWith(status: .loading);

    final data = await _repository.logout();

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) => state = state.copyWith(status: .success),
    );
  }
}
