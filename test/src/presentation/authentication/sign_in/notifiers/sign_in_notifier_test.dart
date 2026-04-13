import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_events.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_notifier.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/authentication_model.dart';
import 'package:trocado/src/domain/contracts/repositories/interface_authentication_repository.dart';

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
  });

  group('PasswordChanged', () {
    test('updates password in state', () {
      final container = makeContainer();

      container
          .read(signInProvider.notifier)
          .dispatch(const PasswordChanged('secret123'));

      expect(container.read(signInProvider).password, 'secret123');
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
      notifier.dispatch(SubmitPressed());

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

        container.read(signInProvider.notifier).dispatch(SubmitPressed());
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

      container.read(signInProvider.notifier).dispatch(SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(signInProvider).status, SignInStatus.failure);
    });
  });
}
