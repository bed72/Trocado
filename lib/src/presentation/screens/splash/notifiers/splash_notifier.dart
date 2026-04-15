import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/presentation/screens/splash/notifiers/splash_state.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'splash_notifier.g.dart';

@riverpod
final class SplashNotifier extends _$SplashNotifier {
  late IAuthenticationRepository _repository;

  @override
  SplashState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    _isLogged();

    return const SplashState();
  }

  Future<void> _isLogged() async {
    final data = await _repository.checkSession();

    state = data.fold(
      (_) => state.copyWith(status: .unauthenticated),
      (_) => state.copyWith(status: .authenticated),
    );
  }
}
