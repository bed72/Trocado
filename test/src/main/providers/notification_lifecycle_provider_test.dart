import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/notification_lifecycle_provider.dart';

import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IMessagingClient messaging;
  late INotificationRepository repository;
  late StreamController<String> controller;

  setUp(() {
    messaging = MockMessagingClient();
    repository = MockNotificationRepository();
    controller = StreamController<String>.broadcast();

    when(() => messaging.onTokenRefresh).thenAnswer((_) => controller.stream);
    when(
      () => repository.registerToken(),
    ).thenAnswer((_) async => const Right(null));
  });

  tearDown(() async {
    await controller.close();
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      messagingClientProvider.overrideWithValue(messaging),
      notificationRepositoryProvider.overrideWithValue(repository),
    ],
  );

  group('NotificationLifecycle', () {
    test('materialization attaches a listener to onTokenRefresh', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      await pumpEventQueue();

      expect(controller.hasListener, isTrue);
      verifyNever(() => repository.registerToken());
    });

    test('single emit triggers registerToken exactly once', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add('token-1');
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(1);
    });

    test('multiple emits trigger one registerToken per emit', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add('token-1');
      controller.add('token-2');
      controller.add('token-3');
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(3);
    });

    test('container dispose cancels the subscription', () async {
      final container = makeContainer();

      container.read(notificationLifecycleProvider);
      await pumpEventQueue();
      expect(controller.hasListener, isTrue);

      container.dispose();
      await pumpEventQueue();

      expect(controller.hasListener, isFalse);
    });

    test('slow registerToken does not block subsequent emits', () async {
      final completer = Completer<Either<Failure, void>>();
      when(
        () => repository.registerToken(),
      ).thenAnswer((_) => completer.future);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add('token-1');
      controller.add('token-2');
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(2);
      expect(completer.isCompleted, isFalse);

      completer.complete(const Right(null));
    });
  });
}
