import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/core/domain/constant/storage_contant.dart';
import 'package:trocado/modules/core/presentation/notifiers/onboarding_notifier.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IStorageRepository repository;

  setUp(() {
    repository = MockStorageRepository();
  });

  group('OnboardingNotifier', () {
    test('should start with initial state false', () {
      final notifier = OnboardingNotifier(repository: repository);

      expect(notifier.success, false);
      expect(notifier.enabled, false);
    });

    test('should toggle state and call save', () async {
      final notifier = OnboardingNotifier(repository: repository);

      when(
        () => repository.save(
          key: StorageConstant.onboarding.key,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      notifier.toggle(true);

      expect(notifier.enabled, true);
      verify(
        () => repository.save(
          key: StorageConstant.onboarding.key,
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('should notify listeners when toggle is called', () {
      int called = 0;
      final notifier = OnboardingNotifier(repository: repository);

      notifier.addListener(() => called++);

      when(
        () => repository.save(
          key: StorageConstant.onboarding.key,
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
          () => repository.get(key: StorageConstant.onboarding.key),
        ).thenAnswer((_) async => null);

        final notifier = OnboardingNotifier(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.enabled, false);
      },
    );

    test(
      'ensureInitialized should do nothing when repository returns invalid bool',
      () async {
        when(
          () => repository.get(key: StorageConstant.onboarding.key),
        ).thenAnswer((_) async => 'invalid');

        final notifier = OnboardingNotifier(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.enabled, false);
      },
    );

    test(
      'ensureInitialized should update state when repository returns "true"',
      () async {
        when(
          () => repository.get(key: StorageConstant.onboarding.key),
        ).thenAnswer((_) async => 'true');

        int called = 0;
        final notifier = OnboardingNotifier(repository: repository);
        notifier.addListener(() => called++);

        await notifier.ensureInitialized();

        expect(called, 1);
        expect(notifier.enabled, true);
      },
    );

    test(
      'ensureInitialized should update state when repository returns "false"',
      () async {
        when(
          () => repository.get(key: StorageConstant.onboarding.key),
        ).thenAnswer((_) async => 'false');

        final notifier = OnboardingNotifier(repository: repository);

        await notifier.ensureInitialized();

        expect(notifier.enabled, false);
      },
    );
  });
}
