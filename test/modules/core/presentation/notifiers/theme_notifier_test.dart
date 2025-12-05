import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IStorageRepository repository;

  setUp(() {
    repository = MockStorageRepository();
  });

  group('ThemeNotifier', () {
    test('should start with initial state ThemeMode.system', () {
      final notifier = ThemeStore(repository: repository);

      expect(notifier.success, ThemeMode.system);
      expect(notifier.isDark, false);
    });

    test('should toggle to dark mode and call save', () async {
      final notifier = ThemeStore(repository: repository);

      when(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      notifier.toggle(true);

      expect(notifier.success, ThemeMode.dark);
      expect(notifier.isDark, true);

      verify(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('should toggle to light mode and call save', () async {
      final notifier = ThemeStore(repository: repository);

      when(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      notifier.toggle(false);

      expect(notifier.success, ThemeMode.light);
      expect(notifier.isDark, false);

      verify(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('should notify listeners when toggle is called', () {
      int called = 0;
      final notifier = ThemeStore(repository: repository);

      notifier.addListener(() => called++);

      when(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      notifier.toggle(true);

      expect(called, 1);
    });

    test(
      'ensureInitialized should do nothing when repository returns null',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => null);

        final notifier = ThemeStore(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.success, ThemeMode.system);
      },
    );

    test(
      'ensureInitialized should do nothing when repository returns invalid bool',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'invalid');

        final notifier = ThemeStore(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.success, ThemeMode.system);
      },
    );

    test(
      'ensureInitialized should set dark mode when repository returns "true"',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'true');

        int called = 0;
        final notifier = ThemeStore(repository: repository);
        notifier.addListener(() => called++);

        await notifier.ensureInitialized();

        expect(called, 1);
        expect(notifier.success, ThemeMode.dark);
        expect(notifier.isDark, true);
      },
    );

    test(
      'ensureInitialized should set light mode when repository returns "false"',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'false');

        final notifier = ThemeStore(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.success, ThemeMode.light);
        expect(notifier.isDark, false);
      },
    );
  });
}
