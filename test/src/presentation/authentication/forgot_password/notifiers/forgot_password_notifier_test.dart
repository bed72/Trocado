import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/core/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_state.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/notifiers/forgot_password_notifier.dart';

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
    container.listen(forgotPasswordProvider, (_, _) {});
    return container;
  }

  group('EmailChanged', () {
    test('updates email in state', () {
      final container = makeContainer();

      container
          .read(forgotPasswordProvider.notifier)
          .dispatch(const EmailChanged('jane@trocado.app'));

      expect(container.read(forgotPasswordProvider).email, 'jane@trocado.app');
    });

    test('clears emailFailure when email changes', () {
      final container = makeContainer();
      final notifier = container.read(forgotPasswordProvider.notifier);

      notifier.dispatch(const SubmitPressed());
      expect(container.read(forgotPasswordProvider).emailFailure, isNotNull);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      expect(container.read(forgotPasswordProvider).emailFailure, isNull);
    });
  });

  group('SubmitPressed', () {
    test('sets emailFailure and keeps status initial when email is empty', () {
      final container = makeContainer();

      container
          .read(forgotPasswordProvider.notifier)
          .dispatch(const SubmitPressed());

      final state = container.read(forgotPasswordProvider);
      expect(state.emailFailure, isNotNull);
      expect(state.status, ForgotPasswordStatus.initial);
      verifyNever(
        () => repository.requestPasswordReset(email: any(named: 'email')),
      );
    });

    test('sets emailFailure when email is invalid', () {
      final container = makeContainer();
      final notifier = container.read(forgotPasswordProvider.notifier);

      notifier.dispatch(const EmailChanged('notanemail'));
      notifier.dispatch(const SubmitPressed());

      expect(container.read(forgotPasswordProvider).emailFailure, isNotNull);
    });

    test('sets status to loading then success', () async {
      when(
        () => repository.requestPasswordReset(email: any(named: 'email')),
      ).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      final notifier = container.read(forgotPasswordProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(forgotPasswordProvider).status,
        ForgotPasswordStatus.loading,
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(forgotPasswordProvider).status,
        ForgotPasswordStatus.success,
      );
    });

    test('sets status to failure with message on error', () async {
      when(
        () => repository.requestPasswordReset(email: any(named: 'email')),
      ).thenAnswer(
        (_) async =>
            const Left(ValidationFailure('Não foi possível enviar o e-mail.')),
      );

      final container = makeContainer();
      final notifier = container.read(forgotPasswordProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(forgotPasswordProvider);
      expect(state.status, ForgotPasswordStatus.failure);
      expect(state.message, 'Não foi possível enviar o e-mail.');
    });
  });
}
