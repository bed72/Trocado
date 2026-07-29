import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';

import 'package:trocado/src/domain/services/interface_connectivity_service.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'splash_notifier.g.dart';

@Riverpod()
final class SplashNotifier extends _$SplashNotifier {
  late IHealthRepository _healthRepository;
  late IConnectivityService _connectivityService;
  late INotificationRepository _notificationRepository;
  late IAuthenticationRepository _authenticationRepository;

  @override
  Future<SplashStatus> build() async {
    _healthRepository = ref.watch(healthRepositoryProvider);
    _connectivityService = ref.watch(connectivityServiceProvider);
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _authenticationRepository = ref.watch(authenticationRepositoryProvider);

    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) return SplashStatus.noConnection;

    // final health = await _healthRepository.check();
    // final isHealthy = health.fold((_) => false, (ok) => ok);
    // if (!isHealthy) return SplashStatus.maintenance;

    return await _checkSession();
  }

  Future<SplashStatus> _checkSession() async {
    final data = await _authenticationRepository.checkSession();

    return data.fold((_) => .unauthenticated, (_) {
      unawaited(_notificationRepository.registerToken());
      return .authenticated;
    });
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}
