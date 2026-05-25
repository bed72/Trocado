import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/notification_lifecycle_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';
import 'package:trocado/src/infrastructure/clients/notification/local_notification_client.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IMessagingClient messagingClient;
  late INotificationRepository repository;
  late StreamController<void> tokenController;
  late ILocalNotificationClient localNotificationClient;
  late StreamController<Map<String, dynamic>> foregroundController;

  setUp(() {
    messagingClient = MockMessagingClient();
    repository = MockNotificationRepository();
    tokenController = StreamController<void>.broadcast();
    localNotificationClient = MockLocalNotificationClient();
    foregroundController = StreamController<Map<String, dynamic>>.broadcast();

    when(
      () => repository.onTokenRefreshed,
    ).thenAnswer((_) => tokenController.stream);
    when(
      () => repository.registerToken(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => messagingClient.onForegroundMessage,
    ).thenAnswer((_) => foregroundController.stream);
    when(
      () => localNotificationClient.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await tokenController.close();
    await foregroundController.close();
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repository),
      messagingClientProvider.overrideWithValue(messagingClient),
      localNotificationClientProvider.overrideWithValue(
        localNotificationClient,
      ),
    ],
  );

  group('NotificationLifecycle', () {
    group('token refresh', () {
      test('materialization attaches a listener to onTokenRefreshed', () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(notificationLifecycleProvider);
        await pumpEventQueue();

        expect(tokenController.hasListener, isTrue);
        verifyNever(() => repository.registerToken());
      });

      test('single emit triggers registerToken exactly once', () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(notificationLifecycleProvider);
        tokenController.add(null);
        await pumpEventQueue();

        verify(() => repository.registerToken()).called(1);
      });

      test('multiple emits trigger one registerToken per emit', () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(notificationLifecycleProvider);
        tokenController.add(null);
        tokenController.add(null);
        tokenController.add(null);
        await pumpEventQueue();

        verify(() => repository.registerToken()).called(3);
      });

      test('slow registerToken does not block subsequent emits', () async {
        final completer = Completer<Either<Failure, void>>();
        when(
          () => repository.registerToken(),
        ).thenAnswer((_) => completer.future);

        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(notificationLifecycleProvider);
        tokenController.add(null);
        tokenController.add(null);
        await pumpEventQueue();

        verify(() => repository.registerToken()).called(2);
        expect(completer.isCompleted, isFalse);

        completer.complete(const Right(null));
      });
    });

    group('foreground messages', () {
      test(
        'foreground message triggers show with correct title and body',
        () async {
          final container = makeContainer();
          addTearDown(container.dispose);

          container.read(notificationLifecycleProvider);
          foregroundController.add({
            'title': 'Gasto compartilhado',
            'body': 'R\$ 50,00',
          });
          await pumpEventQueue();

          verify(
            () => localNotificationClient.show(
              id: any(named: 'id'),
              title: 'Gasto compartilhado',
              body: 'R\$ 50,00',
            ),
          ).called(1);
        },
      );

      test(
        'multiple foreground messages trigger one show per message',
        () async {
          final container = makeContainer();
          addTearDown(container.dispose);

          container.read(notificationLifecycleProvider);
          foregroundController.add({'title': 'First', 'body': 'Body 1'});
          foregroundController.add({'title': 'Second', 'body': 'Body 2'});
          foregroundController.add({'title': 'Third', 'body': 'Body 3'});
          await pumpEventQueue();

          verify(
            () => localNotificationClient.show(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
            ),
          ).called(3);
        },
      );

      test('slow show does not block subsequent foreground messages', () async {
        final completer = Completer<void>();
        when(
          () => localNotificationClient.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => completer.future);

        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(notificationLifecycleProvider);
        foregroundController.add({'title': 'First', 'body': 'Body 1'});
        foregroundController.add({'title': 'Second', 'body': 'Body 2'});
        await pumpEventQueue();

        verify(
          () => localNotificationClient.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).called(2);
        expect(completer.isCompleted, isFalse);

        completer.complete();
      });
    });

    group('disposal', () {
      test('container dispose cancels both subscriptions', () async {
        final container = makeContainer();

        container.read(notificationLifecycleProvider);
        await pumpEventQueue();
        expect(tokenController.hasListener, isTrue);
        expect(foregroundController.hasListener, isTrue);

        container.dispose();
        await pumpEventQueue();

        expect(tokenController.hasListener, isFalse);
        expect(foregroundController.hasListener, isFalse);
      });
    });
  });
}
