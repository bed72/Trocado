import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/presentation/stores/notification_store.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IStorageRepository repository;

  setUp(() {
    repository = MockStorageRepository();
  });

  group('NotificationStore', () {
    test('should start with notification = false', () {
      final store = NotificationStore(repository: repository);

      expect(store.notification, false);
    });

    test('toggle should update notification and call save', () async {
      final store = NotificationStore(repository: repository);

      when(
        () => repository.save(
          key: StorageConstant.notifications.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await store.toggle(true);

      expect(store.notification, true);

      verify(
        () => repository.save(
          value: 'true',
          key: StorageConstant.notifications.key,
        ),
      ).called(1);
    });

    test('toggle should trigger reaction', () async {
      int called = 0;
      final store = NotificationStore(repository: repository);

      final dispose = reaction<bool>(
        (_) => store.notification,
        (_) => called++,
      );

      when(
        () => repository.save(
          value: any(named: 'value'),
          key: StorageConstant.notifications.key,
        ),
      ).thenAnswer((_) async {});

      await store.toggle(true);

      expect(called, 1);

      dispose();
    });

    test(
      'ensureInitialized should do nothing when repository returns null',
      () async {
        when(
          () => repository.get(key: StorageConstant.notifications.key),
        ).thenAnswer((_) async => null);

        final store = NotificationStore(repository: repository);

        await store.ensureInitialized();

        expect(store.notification, false);
      },
    );

    test('ensureInitialized should ignore invalid boolean', () async {
      when(
        () => repository.get(key: StorageConstant.notifications.key),
      ).thenAnswer((_) async => 'invalid');

      final store = NotificationStore(repository: repository);

      await store.ensureInitialized();

      expect(store.notification, false);
    });

    test('ensureInitialized should update notification = true', () async {
      int called = 0;

      when(
        () => repository.get(key: StorageConstant.notifications.key),
      ).thenAnswer((_) async => 'true');

      final store = NotificationStore(repository: repository);

      final dispose = reaction<bool>(
        (_) => store.notification,
        (_) => called++,
      );

      await store.ensureInitialized();

      expect(called, 1);
      expect(store.notification, true);

      dispose();
    });

    test('ensureInitialized should update notification = false', () async {
      when(
        () => repository.get(key: StorageConstant.notifications.key),
      ).thenAnswer((_) async => 'false');

      final store = NotificationStore(repository: repository);

      await store.ensureInitialized();

      expect(store.notification, false);
    });
  });
}
