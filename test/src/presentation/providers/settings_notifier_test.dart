import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/settings_state.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/settings_intent.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/settings_notifier.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/quick_action_service.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import '../../../mocks/mocks.dart';

ProviderContainer _makeContainer(
  IAuthenticationRepository repository,
  IQuickActionService quickActionService,
) {
  final container = ProviderContainer(
    overrides: [
      authenticationRepositoryProvider.overrideWithValue(repository),
      quickActionServiceProvider.overrideWithValue(quickActionService),
    ],
  );
  addTearDown(container.dispose);
  container.listen(settingsProvider, (_, _) {});
  container.read(settingsProvider);
  return container;
}

void main() {
  late IQuickActionService service;
  late IAuthenticationRepository repository;

  setUp(() {
    service = MockQuickActionService();
    repository = MockAuthenticationRepository();
  });

  group('initial state', () {
    test('status is initial', () {
      final container = _makeContainer(repository, service);

      expect(container.read(settingsProvider).status, SettingsStatus.initial);
    });

    test('message is empty', () {
      final container = _makeContainer(repository, service);

      expect(container.read(settingsProvider).message, '');
    });
  });

  group('dispatch — LogoutPressed', () {
    test('sets status to loading then success on successful logout', () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(repository, service);
      final notifier = container.read(settingsProvider.notifier);

      notifier.dispatch(const LogoutPressed());
      expect(container.read(settingsProvider).status, SettingsStatus.loading);

      await pumpEventQueue();

      expect(container.read(settingsProvider).status, SettingsStatus.success);
    });

    test('sets status to failure with message on error', () async {
      when(() => repository.logout()).thenAnswer(
        (_) async => const Left(ValidationFailure('Token inválido.')),
      );

      final container = _makeContainer(repository, service);
      container.read(settingsProvider.notifier).dispatch(const LogoutPressed());
      await pumpEventQueue();

      final state = container.read(settingsProvider);

      expect(state.message, 'Token inválido.');
      expect(state.status, SettingsStatus.failure);
    });

    test('sets status to failure on network error', () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(repository, service);
      container.read(settingsProvider.notifier).dispatch(const LogoutPressed());
      await pumpEventQueue();

      expect(container.read(settingsProvider).status, SettingsStatus.failure);
    });

    test('ignores dispatch when already loading', () async {
      when(() => repository.logout()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Right(null);
      });

      final container = _makeContainer(repository, service);
      final notifier = container.read(settingsProvider.notifier);

      notifier.dispatch(const LogoutPressed());
      notifier.dispatch(const LogoutPressed());

      await pumpEventQueue();

      verify(() => repository.logout()).called(1);
    });
  });
}
