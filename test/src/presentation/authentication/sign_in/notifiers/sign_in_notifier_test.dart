import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';
import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_notifier.dart';

import '../../../../../mocks/mocks.dart';

void main() {
  late IAuthenticationRepository repository;

  setUp(() {
    repository = MockAuthenticationRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInProvider, (_, _) {});
    return container;
  }

  group('EmailChanged', () {
    test('updates email in state', () {
      final container = makeContainer();

      container
          .read(signInProvider.notifier)
          .dispatch(const EmailChanged('jane@trocado.app'));

      expect(container.read(signInProvider).email, 'jane@trocado.app');
    });

    test('clears emailFailure when email changes', () {
      final container = makeContainer();
      final notifier = container.read(signInProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(signInProvider).emailFailure, isNotNull);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      expect(container.read(signInProvider).emailFailure, isNull);
    });
  });

  group('PasswordChanged', () {
    test('updates password in state', () {
      final container = makeContainer();

      container
          .read(signInProvider.notifier)
          .dispatch(const PasswordChanged('secret123'));

      expect(container.read(signInProvider).password, 'secret123');
    });

    test('clears passwordFailure when password changes', () {
      final container = makeContainer();
      final notifier = container.read(signInProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(signInProvider).passwordFailure, isNotNull);

      notifier.dispatch(const PasswordChanged('secret123'));
      expect(container.read(signInProvider).passwordFailure, isNull);
    });
  });

  group('SubmitPressed', () {
    test('sets status to loading during sign-in, then success', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          AuthenticationModel(access: 'access-token', refresh: 'refresh-token'),
        ),
      );

      final container = makeContainer();
      final notifier = container.read(signInProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const SubmitPressed());

      expect(container.read(signInProvider).status, SignInStatus.loading);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(signInProvider).status, SignInStatus.success);
    });

    test(
      'sets status to failure with message on invalid credentials',
      () async {
        when(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'No active account found with the given credentials.',
            ),
          ),
        );

        final container = makeContainer();
        final notifier = container.read(signInProvider.notifier);

        notifier.dispatch(const EmailChanged('jane@trocado.app'));
        notifier.dispatch(const PasswordChanged('secret123'));
        notifier.dispatch(const SubmitPressed());
        await Future<void>.delayed(Duration.zero);

        final state = container.read(signInProvider);
        expect(state.status, SignInStatus.failure);
        expect(
          state.message,
          'No active account found with the given credentials.',
        );
      },
    );

    test('sets status to failure on network error', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = makeContainer();
      final notifier = container.read(signInProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(signInProvider).status, SignInStatus.failure);
    });

    group('validation', () {
      test('sets emailFailure when email is empty', () {
        final container = makeContainer();

        container.read(signInProvider.notifier).dispatch(const SubmitPressed());

        expect(
          container.read(signInProvider).emailFailure,
          'E-mail obrigatório',
        );
      });

      test('sets emailFailure when email format is invalid', () {
        final container = makeContainer();
        final notifier = container.read(signInProvider.notifier);

        notifier.dispatch(const EmailChanged('notanemail'));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(signInProvider).emailFailure,
          'E-mail inválido',
        );
      });

      test('sets passwordFailure when password is empty', () {
        final container = makeContainer();
        final notifier = container.read(signInProvider.notifier);

        notifier.dispatch(const EmailChanged('jane@trocado.app'));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(signInProvider).passwordFailure,
          'Senha obrigatória',
        );
      });

      test('sets passwordFailure when password is shorter than 8 characters', () {
        final container = makeContainer();
        final notifier = container.read(signInProvider.notifier);

        notifier.dispatch(const EmailChanged('jane@trocado.app'));
        notifier.dispatch(const PasswordChanged('1234567'));
        notifier.dispatch(const SubmitPressed());

        expect(
          container.read(signInProvider).passwordFailure,
          'Senha deve ter ao menos 8 caracteres',
        );
      });

      test('sets both failures when both fields are invalid', () {
        final container = makeContainer();

        container.read(signInProvider.notifier).dispatch(const SubmitPressed());

        final state = container.read(signInProvider);
        expect(state.emailFailure, isNotNull);
        expect(state.passwordFailure, isNotNull);
      });

      test('does not call repository when validation fails', () {
        final container = makeContainer();

        container.read(signInProvider.notifier).dispatch(const SubmitPressed());

        verifyNever(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      });

      test('keeps status as initial when validation fails', () {
        final container = makeContainer();

        container.read(signInProvider.notifier).dispatch(const SubmitPressed());

        expect(container.read(signInProvider).status, SignInStatus.initial);
      });
    });
  });
}
