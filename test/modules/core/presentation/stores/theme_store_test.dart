import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/presentation/stores/theme_store.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IStorageRepository repository;

  setUp(() {
    repository = MockStorageRepository();
  });

  group('ThemeStore', () {
    test('should start with theme = ThemeMode.system', () {
      final store = ThemeStore(repository: repository);

      expect(store.isDark, false);
      expect(store.theme, ThemeMode.system);
    });

    test('toggle should set dark mode and call save', () {
      final store = ThemeStore(repository: repository);

      when(
        () => repository.save(
          value: any(named: 'value'),
          key: StorageConstant.theme.key,
        ),
      ).thenAnswer((_) async {});

      store.onChanged(true);

      expect(store.theme, ThemeMode.dark);
      expect(store.isDark, true);

      verify(
        () => repository.save(key: StorageConstant.theme.key, value: 'true'),
      ).called(1);
    });

    test('toggle should set light mode and call save', () {
      final store = ThemeStore(repository: repository);

      when(
        () => repository.save(
          value: any(named: 'value'),
          key: StorageConstant.theme.key,
        ),
      ).thenAnswer((_) async {});

      store.onChanged(false);

      expect(store.theme, ThemeMode.light);
      expect(store.isDark, false);

      verify(
        () => repository.save(key: StorageConstant.theme.key, value: 'false'),
      ).called(1);
    });

    test('toggle should trigger reaction', () {
      int called = 0;
      final store = ThemeStore(repository: repository);

      final dispose = reaction<ThemeMode>((_) => store.theme, (_) => called++);

      when(
        () => repository.save(
          key: StorageConstant.theme.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      store.onChanged(true);

      expect(called, 1);

      dispose();
    });

    test(
      'ensureInitialized should do nothing when repository returns null',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => null);

        final store = ThemeStore(repository: repository);

        await store.ensureInitialized();

        expect(store.theme, ThemeMode.system);
      },
    );

    test(
      'ensureInitialized should do nothing when repository returns invalid bool',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'invalid');

        final store = ThemeStore(repository: repository);

        await store.ensureInitialized();

        expect(store.theme, ThemeMode.system);
      },
    );

    test(
      'ensureInitialized should set dark mode when repository returns "true"',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'true');

        int called = 0;
        final store = ThemeStore(repository: repository);

        final dispose = reaction<ThemeMode>(
          (_) => store.theme,
          (_) => called++,
        );

        await store.ensureInitialized();

        expect(called, 1);
        expect(store.isDark, true);
        expect(store.theme, ThemeMode.dark);

        dispose();
      },
    );

    test(
      'ensureInitialized should set light mode when repository returns "false"',
      () async {
        when(
          () => repository.get(key: StorageConstant.theme.key),
        ).thenAnswer((_) async => 'false');

        final store = ThemeStore(repository: repository);

        await store.ensureInitialized();

        expect(store.isDark, false);
        expect(store.theme, ThemeMode.light);
      },
    );
  });
}
