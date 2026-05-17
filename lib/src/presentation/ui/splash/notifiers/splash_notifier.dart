import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';

import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'splash_notifier.g.dart';

@Riverpod()
final class SplashNotifier extends _$SplashNotifier {
  late INotificationRepository _notificationRepository;
  late IAuthenticationRepository _authenticationRepository;

  @override
  Future<SplashStatus> build() async {
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _authenticationRepository = ref.watch(authenticationRepositoryProvider);

    return await _checkSession();
  }

  Future<SplashStatus> _checkSession() async {
    final data = await _authenticationRepository.checkSession();

    return data.fold((_) => .unauthenticated, (_) {
      unawaited(_notificationRepository.registerToken());
      return .authenticated;
    });
  }
}
