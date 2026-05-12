import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';
import 'package:trocado/src/presentation/ui/splash/notifiers/splash_notifier.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late INotificationRepository notificationRepository;
  late IAuthenticationRepository authenticationRepository;

  setUp(() {
    notificationRepository = MockNotificationRepository();
    authenticationRepository = MockAuthenticationRepository();

    when(
      () => notificationRepository.registerToken(),
    ).thenAnswer((_) async => const Right(null));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
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

  group('build', () {
    test(
      'authenticated session emits authenticated and triggers registerToken',
      () async {
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

    test(
      'unauthenticated session emits unauthenticated and skips registerToken',
      () async {
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
