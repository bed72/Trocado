import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_state.dart';
import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_intent.dart';
import 'package:trocado/src/presentation/ui/profile/purge/notifiers/profile_purge_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _validPassword = 'MyPassword!456';
const _user = UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe');

void main() {
  late IUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.me()).thenAnswer((_) async => const Right(_user));
  });

  Future<ProviderContainer> makeContainer({bool primeUser = true}) async {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(profilePurgeProvider, (_, _) {});
    if (primeUser) {
      container.listen(userProvider, (_, _) {});
      await container.read(userProvider.future);
    }
    return container;
  }

  group('build', () {
    test('returns initial state', () async {
      final container = await makeContainer(primeUser: false);

      expect(container.read(profilePurgeProvider), const ProfilePurgeState());
    });
  });

  group('PasswordChanged', () {
    test('updates password and clears passwordFailure', () async {
      final container = await makeContainer(primeUser: false);
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(
        container.read(profilePurgeProvider).passwordFailure,
        'Senha obrigatória',
      );

      notifier.dispatch(const PasswordChanged(_validPassword));

      final state = container.read(profilePurgeProvider);
      expect(state.password, _validPassword);
      expect(state.passwordFailure, isNull);
    });
  });

  group('PasswordVisibilityToggled', () {
    test('toggles obscurePassword', () async {
      final container = await makeContainer(primeUser: false);
      final notifier = container.read(profilePurgeProvider.notifier);

      expect(container.read(profilePurgeProvider).obscurePassword, isTrue);

      notifier.dispatch(const PasswordVisibilityToggled());
      expect(container.read(profilePurgeProvider).obscurePassword, isFalse);

      notifier.dispatch(const PasswordVisibilityToggled());
      expect(container.read(profilePurgeProvider).obscurePassword, isTrue);
    });
  });

  group('ValidatePressed', () {
    test('populates passwordFailure when password is empty', () async {
      final container = await makeContainer(primeUser: false);
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const ValidatePressed());

      expect(
        container.read(profilePurgeProvider).passwordFailure,
        'Senha obrigatória',
      );
    });

    test('clears passwordFailure when password is valid', () async {
      final container = await makeContainer(primeUser: false);
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const ValidatePressed());
      expect(container.read(profilePurgeProvider).passwordFailure, isNotNull);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const ValidatePressed());

      expect(container.read(profilePurgeProvider).passwordFailure, isNull);
    });

    test('does not call repository on its own', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const ValidatePressed());

      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => repository.purge(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('SubmitPressed', () {
    test('sets passwordFailure when password is empty (defensive)', () async {
      final container = await makeContainer();
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(profilePurgeProvider).passwordFailure,
        'Senha obrigatória',
      );
      verifyNever(
        () => repository.purge(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test(
      'sets status to loading then success and invalidates userProvider on success',
      () async {
        when(
          () => repository.purge(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final container = await makeContainer();
        verify(() => repository.me()).called(1);

        final notifier = container.read(profilePurgeProvider.notifier);

        notifier.dispatch(const PasswordChanged(_validPassword));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(profilePurgeProvider).status,
          ProfilePurgeStatus.loading,
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(profilePurgeProvider).status,
          ProfilePurgeStatus.success,
        );
        verify(
          () => repository.purge(email: _user.email, password: _validPassword),
        ).called(1);

        await container.read(userProvider.future);
        verify(() => repository.me()).called(1);
      },
    );

    test('sets status to failure with message on repository failure', () async {
      when(
        () => repository.purge(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Account must be deactivated before purge.'),
        ),
      );

      final container = await makeContainer();
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(profilePurgeProvider);
      expect(state.status, ProfilePurgeStatus.failure);
      expect(state.message, 'Account must be deactivated before purge.');
    });

    test('does not call repository when already loading', () async {
      when(
        () => repository.purge(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final container = await makeContainer();
      final notifier = container.read(profilePurgeProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const SubmitPressed());
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      verify(
        () => repository.purge(email: _user.email, password: _validPassword),
      ).called(1);
    });

    test(
      'sets failure with defensive message when userProvider is not AsyncData',
      () async {
        final container = await makeContainer(primeUser: false);

        final notifier = container.read(profilePurgeProvider.notifier);
        notifier.dispatch(const PasswordChanged(_validPassword));
        notifier.dispatch(const SubmitPressed());

        final state = container.read(profilePurgeProvider);

        expect(state.status, ProfilePurgeStatus.failure);
        expect(state.message, 'Não foi possível identificar o usuário.');
        verifyNever(
          () => repository.purge(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );
  });
}
