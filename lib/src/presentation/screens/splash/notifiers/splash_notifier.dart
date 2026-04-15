import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/presentation/screens/splash/notifiers/splash_state.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'splash_notifier.g.dart';

@riverpod
final class SplashNotifier extends _$SplashNotifier {
  late IAuthenticationRepository _repository;

  @override
  Future<SplashStatus> build() async {
    _repository = ref.watch(authenticationRepositoryProvider);

    return await _checkSession();
  }

  Future<SplashStatus> _checkSession() async {
    final data = await _repository.checkSession();

    return data.fold((_) => .unauthenticated, (_) => .authenticated);
  }
}
