import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/sign_up_model.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _signUpModel = SignUpModel(
  access: 'access-token',
  refresh: 'refresh-token',
  user: UserModel(id: 42, name: 'jane', email: 'jane@trocado.app'),
);

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
    container.listen(signUpProvider, (_, _) {});
    return container;
  }

  group('EmailChanged', () {
    test('updates email in state', () {
      final container = makeContainer();

      container
          .read(signUpProvider.notifier)
          .dispatch(const EmailChanged('jane@trocado.app'));

      expect(container.read(signUpProvider).email, 'jane@trocado.app');
    });

    test('clears emailFailure when email changes', () {
      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(signUpProvider).emailFailure, isNotNull);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      expect(container.read(signUpProvider).emailFailure, isNull);
    });
  });

  group('PasswordChanged', () {
    test('updates password in state', () {
      final container = makeContainer();

      container
          .read(signUpProvider.notifier)
          .dispatch(const PasswordChanged('secret123'));

      expect(container.read(signUpProvider).password, 'secret123');
    });

    test('clears passwordFailure when password changes', () {
      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(signUpProvider).passwordFailure, isNotNull);

      notifier.dispatch(const PasswordChanged('secret123'));
      expect(container.read(signUpProvider).passwordFailure, isNull);
    });
  });

  group('TermsToggled', () {
    test('updates termsAccepted in state', () {
      final container = makeContainer();

      container
          .read(signUpProvider.notifier)
          .dispatch(const TermsToggled(true));

      expect(container.read(signUpProvider).termsAccepted, isTrue);
    });

    test('clears termsFailure when terms toggled', () {
      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(signUpProvider).termsFailure, isNotNull);

      notifier.dispatch(const TermsToggled(true));
      expect(container.read(signUpProvider).termsFailure, isNull);
    });
  });

  group('SubmitPressed', () {
    test(
      'sets all failures and keeps status initial when all fields are empty',
      () {
        final container = makeContainer();

        container.read(signUpProvider.notifier).dispatch(const SubmitPressed());

        final state = container.read(signUpProvider);

        expect(state.emailFailure, isNotNull);
        expect(state.termsFailure, isNotNull);
        expect(state.passwordFailure, isNotNull);
        expect(state.status, SignUpStatus.initial);
        verifyNever(
          () => repository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test('sets only emailFailure when email is invalid', () {
      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const TermsToggled(true));
      notifier.dispatch(const SubmitPressed());

      final state = container.read(signUpProvider);
      expect(state.termsFailure, isNull);
      expect(state.emailFailure, isNotNull);
      expect(state.passwordFailure, isNull);
    });

    test('sets only termsFailure when terms not accepted', () {
      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const SubmitPressed());

      final state = container.read(signUpProvider);
      expect(state.emailFailure, isNull);
      expect(state.passwordFailure, isNull);
      expect(state.termsFailure, isNotNull);
    });

    test('sets status to loading then success', () async {
      when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(_signUpModel));

      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const TermsToggled(true));
      notifier.dispatch(const SubmitPressed());

      expect(container.read(signUpProvider).status, SignUpStatus.loading);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(signUpProvider).status, SignUpStatus.success);
    });

    test('sets status to failure with message on error', () async {
      when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ValidationFailure('Este e-mail já está cadastrado.')),
      );

      final container = makeContainer();
      final notifier = container.read(signUpProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('secret123'));
      notifier.dispatch(const TermsToggled(true));
      notifier.dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(signUpProvider);
      expect(state.status, SignUpStatus.failure);
      expect(state.message, 'Este e-mail já está cadastrado.');
    });
  });
}
