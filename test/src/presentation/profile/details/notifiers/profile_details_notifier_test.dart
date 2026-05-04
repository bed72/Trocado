import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_state.dart';
import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_intent.dart';
import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _user = UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe');

void main() {
  late IUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.me()).thenAnswer((_) async => const Right(_user));
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(profileDetailsProvider, (_, _) {});
    return container;
  }

  group('build', () {
    test('returns initial state', () {
      final container = makeContainer();

      expect(
        container.read(profileDetailsProvider).status,
        ProfileDetailsStatus.initial,
      );
    });
  });

  group('DeactivatePressed', () {
    test('sets status to loading then success on success', () async {
      when(
        () => repository.deactivate(),
      ).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      final notifier = container.read(profileDetailsProvider.notifier);

      notifier.dispatch(const DeactivatePressed());

      expect(
        container.read(profileDetailsProvider).status,
        ProfileDetailsStatus.loading,
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(profileDetailsProvider).status,
        ProfileDetailsStatus.success,
      );
    });

    test('invalidates userProvider on success', () async {
      when(
        () => repository.deactivate(),
      ).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      container.listen(userProvider, (_, _) {});
      await container.read(userProvider.future);

      verify(() => repository.me()).called(1);

      container
          .read(profileDetailsProvider.notifier)
          .dispatch(const DeactivatePressed());
      await Future<void>.delayed(Duration.zero);
      await container.read(userProvider.future);

      verify(() => repository.me()).called(1);
    });

    test('sets status to failure with message on error', () async {
      when(() => repository.deactivate()).thenAnswer(
        (_) async => const Left(ValidationFailure('Conta inválida.')),
      );

      final container = makeContainer();
      final notifier = container.read(profileDetailsProvider.notifier);

      notifier.dispatch(const DeactivatePressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(profileDetailsProvider);
      expect(state.status, ProfileDetailsStatus.failure);
      expect(state.message, 'Conta inválida.');
    });

    test('does not call repository when already loading', () async {
      when(
        () => repository.deactivate(),
      ).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      final notifier = container.read(profileDetailsProvider.notifier);

      notifier.dispatch(const DeactivatePressed());
      notifier.dispatch(const DeactivatePressed());

      await Future<void>.delayed(Duration.zero);

      verify(() => repository.deactivate()).called(1);
    });
  });
}
