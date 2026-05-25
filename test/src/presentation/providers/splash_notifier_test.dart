import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';
import 'package:trocado/src/presentation/ui/splash/notifiers/splash_notifier.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/interface_connectivity_service.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IConnectivityService connectivityService;
  late IHealthRepository healthRepository;
  late INotificationRepository notificationRepository;
  late IAuthenticationRepository authenticationRepository;

  setUp(() {
    connectivityService = MockConnectivityService();
    healthRepository = MockHealthRepository();
    notificationRepository = MockNotificationRepository();
    authenticationRepository = MockAuthenticationRepository();

    when(
      () => notificationRepository.registerToken(),
    ).thenAnswer((_) async => const Right(null));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(connectivityService),
        healthRepositoryProvider.overrideWithValue(healthRepository),
        notificationRepositoryProvider.overrideWithValue(
          notificationRepository,
        ),
        authenticationRepositoryProvider.overrideWithValue(
          authenticationRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(splashProvider, (_, _) {});
    await container.read(splashProvider.future);
    return container;
  }

  group('no connection', () {
    test('emits noConnection when device has no internet', () async {
      when(
        () => connectivityService.hasConnection(),
      ).thenAnswer((_) async => false);

      final container = await makeContainer();

      expect(
        container.read(splashProvider).asData?.value,
        SplashStatus.noConnection,
      );
      verifyNever(() => healthRepository.check());
      verifyNever(() => authenticationRepository.checkSession());
    });
  });

  group('maintenance', () {
    test('emits maintenance when health check returns Left', () async {
      when(
        () => connectivityService.hasConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => healthRepository.check(),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = await makeContainer();

      expect(
        container.read(splashProvider).asData?.value,
        SplashStatus.maintenance,
      );
      verifyNever(() => authenticationRepository.checkSession());
    });

    test('emits maintenance when health status is not ok', () async {
      when(
        () => connectivityService.hasConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => healthRepository.check(),
      ).thenAnswer((_) async => const Right(false));

      final container = await makeContainer();

      expect(
        container.read(splashProvider).asData?.value,
        SplashStatus.maintenance,
      );
      verifyNever(() => authenticationRepository.checkSession());
    });
  });

  group('authenticated', () {
    test(
      'emits authenticated and triggers registerToken when healthy and session valid',
      () async {
        when(
          () => connectivityService.hasConnection(),
        ).thenAnswer((_) async => true);
        when(
          () => healthRepository.check(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => authenticationRepository.checkSession(),
        ).thenAnswer((_) async => const Right(null));

        final container = await makeContainer();
        await pumpEventQueue();

        expect(
          container.read(splashProvider).asData?.value,
          SplashStatus.authenticated,
        );
        verify(() => notificationRepository.registerToken()).called(1);
      },
    );
  });

  group('unauthenticated', () {
    test(
      'emits unauthenticated and skips registerToken when healthy but session invalid',
      () async {
        when(
          () => connectivityService.hasConnection(),
        ).thenAnswer((_) async => true);
        when(
          () => healthRepository.check(),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => authenticationRepository.checkSession(),
        ).thenAnswer((_) async => const Left(UnknownFailure()));

        final container = await makeContainer();
        await pumpEventQueue();

        expect(
          container.read(splashProvider).asData?.value,
          SplashStatus.unauthenticated,
        );
        verifyNever(() => notificationRepository.registerToken());
      },
    );
  });
}
