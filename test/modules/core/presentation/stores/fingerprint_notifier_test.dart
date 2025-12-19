import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/presentation/stores/fingerprint_store.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IStorageRepository repository;

  setUp(() {
    repository = MockStorageRepository();
  });

  group('FingerprintStore', () {
    test('should start with fingerprint = false', () {
      final store = FingerprintStore(repository: repository);

      expect(store.fingerprint, false);
    });

    test('toggle should update fingerprint and call save', () async {
      final store = FingerprintStore(repository: repository);

      when(
        () => repository.save(
          value: any(named: 'value'),
          key: StorageConstant.fingerprint.key,
        ),
      ).thenAnswer((_) async {});

      await store.onChanged(true);

      expect(store.fingerprint, true);

      verify(
        () => repository.save(
          value: 'true',
          key: StorageConstant.fingerprint.key,
        ),
      ).called(1);
    });

    test('toggle should trigger reaction', () async {
      int called = 0;
      final store = FingerprintStore(repository: repository);

      final dispose = reaction<bool>((_) => store.fingerprint, (_) => called++);

      when(
        () => repository.save(
          value: any(named: 'value'),
          key: StorageConstant.fingerprint.key,
        ),
      ).thenAnswer((_) async {});

      await store.onChanged(true);

      expect(called, 1);

      dispose();
    });

    test(
      'ensureInitialized should do nothing if repository returns null',
      () async {
        when(
          () => repository.get(key: StorageConstant.fingerprint.key),
        ).thenAnswer((_) async => null);

        final store = FingerprintStore(repository: repository);

        await store.ensureInitialized();

        expect(store.fingerprint, false);
      },
    );

    test('ensureInitialized should ignore invalid bool string', () async {
      when(
        () => repository.get(key: StorageConstant.fingerprint.key),
      ).thenAnswer((_) async => 'invalid');

      final store = FingerprintStore(repository: repository);

      await store.ensureInitialized();

      expect(store.fingerprint, false);
    });

    test(
      'ensureInitialized should set fingerprint = true when repository returns "true"',
      () async {
        int called = 0;

        when(
          () => repository.get(key: StorageConstant.fingerprint.key),
        ).thenAnswer((_) async => 'true');

        final store = FingerprintStore(repository: repository);

        final dispose = reaction<bool>(
          (_) => store.fingerprint,
          (_) => called++,
        );

        await store.ensureInitialized();

        expect(called, 1);
        expect(store.fingerprint, true);

        dispose();
      },
    );

    test(
      'ensureInitialized should set fingerprint = false when repository returns "false"',
      () async {
        when(
          () => repository.get(key: StorageConstant.fingerprint.key),
        ).thenAnswer((_) async => 'false');

        final store = FingerprintStore(repository: repository);

        await store.ensureInitialized();

        expect(store.fingerprint, false);
      },
    );
  });
}
