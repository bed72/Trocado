import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart';
import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_intent.dart';
import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _validPassword = 'MyPassword!456';
const _user = UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe');

void main() {
  late IUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.me()).thenAnswer((_) async => const Right(_user));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(profileDeleteProvider, (_, _) {});
    return container;
  }

  group('build', () {
    test('returns initial state', () async {
      final container = await makeContainer();

      expect(container.read(profileDeleteProvider), const ProfileDeleteState());
    });
  });

  group('PasswordChanged', () {
    test('updates password and clears passwordFailure', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(
        container.read(profileDeleteProvider).passwordFailure,
        'Senha obrigatória',
      );

      notifier.dispatch(const PasswordChanged(_validPassword));

      final state = container.read(profileDeleteProvider);
      expect(state.password, _validPassword);
      expect(state.passwordFailure, isNull);
    });
  });

  group('PasswordVisibilityToggled', () {
    test('toggles obscurePassword', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      expect(container.read(profileDeleteProvider).obscurePassword, isTrue);

      notifier.dispatch(const PasswordVisibilityToggled());
      expect(container.read(profileDeleteProvider).obscurePassword, isFalse);

      notifier.dispatch(const PasswordVisibilityToggled());
      expect(container.read(profileDeleteProvider).obscurePassword, isTrue);
    });
  });

  group('ValidatePressed', () {
    test('populates passwordFailure when password is empty', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const ValidatePressed());

      expect(
        container.read(profileDeleteProvider).passwordFailure,
        'Senha obrigatória',
      );
    });

    test('clears passwordFailure when password is valid', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const ValidatePressed());
      expect(container.read(profileDeleteProvider).passwordFailure, isNotNull);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const ValidatePressed());

      expect(container.read(profileDeleteProvider).passwordFailure, isNull);
    });

    test('does not call repository on its own', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const ValidatePressed());

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repository.delete(password: any(named: 'password')));
    });
  });

  group('SubmitPressed', () {
    test('sets passwordFailure when password is empty (defensive)', () async {
      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(profileDeleteProvider).passwordFailure,
        'Senha obrigatória',
      );
      verifyNever(() => repository.delete(password: any(named: 'password')));
    });

    test(
      'sets status to loading then success and invalidates userProvider on success',
      () async {
        when(
          () => repository.delete(password: any(named: 'password')),
        ).thenAnswer((_) async => const Right(null));

        final container = await makeContainer();
        container.listen(userProvider, (_, _) {});
        await container.read(userProvider.future);
        verify(() => repository.me()).called(1);

        final notifier = container.read(profileDeleteProvider.notifier);

        notifier.dispatch(const PasswordChanged(_validPassword));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(profileDeleteProvider).status,
          ProfileDeleteStatus.loading,
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(profileDeleteProvider).status,
          ProfileDeleteStatus.success,
        );
        verify(() => repository.delete(password: _validPassword)).called(1);

        await container.read(userProvider.future);
        verify(() => repository.me()).called(1);
      },
    );

    test('sets status to failure with message on repository failure', () async {
      when(
        () => repository.delete(password: any(named: 'password')),
      ).thenAnswer(
        (_) async => const Left(ValidationFailure('Invalid credentials.')),
      );

      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(profileDeleteProvider);
      expect(state.status, ProfileDeleteStatus.failure);
      expect(state.message, 'Invalid credentials.');
    });

    test('does not call repository when already loading', () async {
      when(
        () => repository.delete(password: any(named: 'password')),
      ).thenAnswer((_) async => const Right(null));

      final container = await makeContainer();
      final notifier = container.read(profileDeleteProvider.notifier);

      notifier.dispatch(const PasswordChanged(_validPassword));
      notifier.dispatch(const SubmitPressed());
      notifier.dispatch(const SubmitPressed());

      await Future<void>.delayed(Duration.zero);

      verify(() => repository.delete(password: _validPassword)).called(1);
    });
  });
}
