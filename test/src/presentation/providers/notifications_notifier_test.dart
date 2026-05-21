import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';
import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_notifier.dart';

import '../../../mocks/mocks.dart';

const _first = [
  NotificationModel(
    id: 1,
    title: 'Nova despesa',
    createdAt: 1747000000000,
    type: .sharedExpenseCreated,
    description: 'Gabriel registrou R\$ 85,50.',
  ),
  NotificationModel(
    id: 2,
    type: NotificationTypeEnum.budgetEightyPercent,
    title: 'Orçamento 80%',
    description: 'Atenção.',
    createdAt: 1746990000000,
  ),
];

const _second = [
  NotificationModel(
    id: 3,
    type: NotificationTypeEnum.unknown,
    title: 'Aviso',
    description: 'Algo.',
    createdAt: 1746000000000,
  ),
];

ProviderContainer _makeContainer({
  required INotificationRepository repository,
  required ICoupleRepository coupleRepository,
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      coupleRepositoryProvider.overrideWithValue(coupleRepository),
      notificationRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late INotificationRepository repository;
  late ICoupleRepository coupleRepository;
  late IDateFormatterService dateFormatter;

  setUp(() {
    repository = MockNotificationRepository();
    coupleRepository = MockCoupleRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => coupleRepository.findActive(),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));
    when(() => dateFormatter.formatTime(any())).thenReturn('14:30');
    when(() => dateFormatter.relativeGroupHeader(any())).thenReturn('Hoje');
  });

  group('build', () {
    test('AsyncData with first page items and nextCursor on success', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      final state = await container.read(notificationsProvider.future);

      expect(state.items.map((item) => item.notification.id), [1, 2]);
      expect(state.items.first.formattedTime, '14:30');
      expect(state.nextCursor, 'CUR1');
      expect(state.isLoadingMore, isFalse);
      expect(state.loadMoreFailure, isNull);

      verify(() => repository.findAll(cursor: null)).called(1);
    });

    test('AsyncError when repository returns Left', () async {
      when(
        () => repository.findAll(cursor: any(named: 'cursor')),
      ).thenAnswer((_) async => Left(const NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      container.read(notificationsProvider);

      await pumpEventQueue();

      final state = container.read(notificationsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    });
  });

  group('loadMore', () {
    test('appends next page items and updates cursor', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer((
        invocation,
      ) async {
        final cursor = invocation.namedArguments[#cursor];
        if (cursor == null) {
          return const Right(
            NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
          );
        }
        return const Right(
          NotificationsPageModel(notifications: _second, nextCursor: null),
        );
      });

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).loadMore();

      final state = container.read(notificationsProvider).value!;
      expect(state.nextCursor, isNull);
      expect(state.isLoadingMore, isFalse);
      expect(state.items.map((item) => item.notification.id), [1, 2, 3]);
    });

    test('no-op when nextCursor is null', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).loadMore();

      verify(() => repository.findAll(cursor: null)).called(1);
      verifyNever(() => repository.findAll(cursor: 'CUR1'));
    });

    test('sets loadMoreFailure on Left without losing items', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer((
        invocation,
      ) async {
        final cursor = invocation.namedArguments[#cursor];
        if (cursor == null) {
          return const Right(
            NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
          );
        }
        return Left(const NetworkFailure());
      });

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).loadMore();

      final state = container.read(notificationsProvider).value!;
      expect(state.nextCursor, 'CUR1');
      expect(state.isLoadingMore, isFalse);
      expect(state.loadMoreFailure, isA<NetworkFailure>());
      expect(state.items.map((item) => item.notification.id), [1, 2]);
    });
  });

  group('deleteAll', () {
    test('clears items, groups and nextCursor on success', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.deleteAll(),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).deleteAll();

      final state = container.read(notificationsProvider).value!;

      expect(state.items, isEmpty);
      expect(state.groups, isEmpty);
      expect(state.nextCursor, isNull);
      expect(state.isDeletingAll, isFalse);
      expect(state.deleteAllFailure, isNull);
    });

    test('keeps items and sets deleteAllFailure on failure', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.deleteAll(),
      ).thenAnswer((_) async => Left(const NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).deleteAll();

      final state = container.read(notificationsProvider).value!;
      expect(state.items.map((item) => item.notification.id), [1, 2]);
      expect(state.nextCursor, 'CUR1');
      expect(state.isDeletingAll, isFalse);
      expect(state.deleteAllFailure, isA<NetworkFailure>());
    });

    test('no-op when already deleting', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );

      final completer = Completer<Either<Failure, void>>();
      when(() => repository.deleteAll()).thenAnswer((_) => completer.future);

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      final notifier = container.read(notificationsProvider.notifier);
      final first = notifier.deleteAll();
      final second = notifier.deleteAll();

      completer.complete(const Right(null));
      await Future.wait([first, second]);

      verify(() => repository.deleteAll()).called(1);
    });
  });

  group('deleteById', () {
    test('removes item from items and groups on success', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.deleteById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).deleteById(1);

      final state = container.read(notificationsProvider).value!;
      expect(state.items.map((item) => item.notification.id), [2]);
      expect(state.deleteFailure, isNull);
      verify(() => repository.deleteById(id: 1)).called(1);
    });

    test('no-op when id is not found in items', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).deleteById(999);

      final state = container.read(notificationsProvider).value!;
      expect(state.items.map((item) => item.notification.id), [1, 2]);
      verifyNever(() => repository.deleteById(id: any(named: 'id')));
    });

    test(
      'restores item at original index on failure and sets deleteFailure',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => const Right(
            NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
          ),
        );
        when(
          () => repository.deleteById(id: any(named: 'id')),
        ).thenAnswer((_) async => Left(const NetworkFailure()));

        final container = _makeContainer(
          repository: repository,
          coupleRepository: coupleRepository,
          dateFormatter: dateFormatter,
        );
        container.listen(notificationsProvider, (_, _) {});
        await container.read(notificationsProvider.future);

        await container.read(notificationsProvider.notifier).deleteById(2);

        final state = container.read(notificationsProvider).value!;
        expect(state.items.map((item) => item.notification.id), [1, 2]);
        expect(state.deleteFailure, isA<NetworkFailure>());
      },
    );
  });

  group('couple label gating', () {
    final coupleModel = CoupleModel(
      id: 7,
      createdAt: 1746000000000,
      partner: const UserModel(id: 2, name: 'Kira', email: 'kira@trocado.app'),
    );

    test('hides label for sharedExpenseCreated when solo', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      final state = await container.read(notificationsProvider.future);

      final sharedItem = state.items.firstWhere(
        (item) =>
            item.notification.type == NotificationTypeEnum.sharedExpenseCreated,
      );
      final budgetItem = state.items.firstWhere(
        (item) =>
            item.notification.type == NotificationTypeEnum.budgetEightyPercent,
      );
      expect(sharedItem.showLabel, isFalse);
      expect(budgetItem.showLabel, isTrue);
    });

    test('shows label for unknown when solo', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _second, nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      final state = await container.read(notificationsProvider.future);

      expect(state.items.first.showLabel, isTrue);
    });

    test('shows label for all types when in couple', () async {
      when(
        () => coupleRepository.findActive(),
      ).thenAnswer((_) async => Right(coupleModel));
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsPageModel(notifications: _first, nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      final state = await container.read(notificationsProvider.future);

      expect(state.items.every((item) => item.showLabel), isTrue);
    });

    test('loadMore preserves solo gating across pages', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer((
        invocation,
      ) async {
        final cursor = invocation.namedArguments[#cursor];
        if (cursor == null) {
          return const Right(
            NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
          );
        }
        return const Right(
          NotificationsPageModel(notifications: _second, nextCursor: null),
        );
      });

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).loadMore();

      final state = container.read(notificationsProvider).value!;
      final shared = state.items.firstWhere(
        (item) =>
            item.notification.type == NotificationTypeEnum.sharedExpenseCreated,
      );
      final budget = state.items.firstWhere(
        (item) =>
            item.notification.type == NotificationTypeEnum.budgetEightyPercent,
      );
      final unknown = state.items.firstWhere(
        (item) => item.notification.type == NotificationTypeEnum.unknown,
      );

      expect(shared.showLabel, isFalse);
      expect(budget.showLabel, isTrue);
      expect(unknown.showLabel, isTrue);
    });
  });

  group('refresh', () {
    test('reloads the first page from scratch', () async {
      int callCount = 0;
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer((
        _,
      ) async {
        callCount++;
        if (callCount == 1) {
          return const Right(
            NotificationsPageModel(notifications: _first, nextCursor: 'CUR1'),
          );
        }
        return const Right(
          NotificationsPageModel(notifications: _second, nextCursor: null),
        );
      });

      final container = _makeContainer(
        repository: repository,
        coupleRepository: coupleRepository,
        dateFormatter: dateFormatter,
      );
      container.listen(notificationsProvider, (_, _) {});
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).refresh();

      final state = container.read(notificationsProvider).value!;

      expect(state.nextCursor, isNull);
      expect(state.items.map((item) => item.notification.id), [3]);
    });
  });
}
