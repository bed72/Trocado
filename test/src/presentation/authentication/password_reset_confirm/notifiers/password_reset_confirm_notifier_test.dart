import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/core/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_notifier.dart';

import '../../../../../mocks/mocks.dart';

const _uid = 'Mw';
const _token = 'bm7gkj-1a2b3c4d';

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
    container.listen(
      passwordResetConfirmProvider(uid: _uid, token: _token),
      (_, _) {},
    );
    return container;
  }

  group('NewPasswordChanged', () {
    test('updates newPassword in state', () {
      final container = makeContainer();

      container
          .read(passwordResetConfirmProvider(uid: _uid, token: _token).notifier)
          .dispatch(const NewPasswordChanged('NewSecure!456'));

      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .newPassword,
        'NewSecure!456',
      );
    });

    test('clears newPasswordFailure when password changes', () {
      final container = makeContainer();
      final notifier = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token).notifier,
      );

      notifier.dispatch(const SubmitPressed());
      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .newPasswordFailure,
        isNotNull,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .newPasswordFailure,
        isNull,
      );
    });
  });

  group('ConfirmPasswordChanged', () {
    test('updates confirmPassword in state', () {
      final container = makeContainer();

      container
          .read(passwordResetConfirmProvider(uid: _uid, token: _token).notifier)
          .dispatch(const ConfirmPasswordChanged('NewSecure!456'));

      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .confirmPassword,
        'NewSecure!456',
      );
    });
  });

  group('SubmitPressed', () {
    test('sets newPasswordFailure and keeps status initial when password is empty', () {
      final container = makeContainer();

      container
          .read(passwordResetConfirmProvider(uid: _uid, token: _token).notifier)
          .dispatch(const SubmitPressed());

      final state = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token),
      );
      expect(state.newPasswordFailure, isNotNull);
      expect(state.status, PasswordResetConfirmStatus.initial);
      verifyNever(
        () => repository.confirmPasswordReset(
          uid: any(named: 'uid'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test('sets confirmPasswordFailure when passwords do not match', () {
      final container = makeContainer();
      final notifier = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token).notifier,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('Different!789'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .confirmPasswordFailure,
        isNotNull,
      );
    });

    test('sets status to loading then success', () async {
      when(
        () => repository.confirmPasswordReset(
          uid: any(named: 'uid'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      final notifier = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token).notifier,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('NewSecure!456'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .status,
        PasswordResetConfirmStatus.loading,
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(passwordResetConfirmProvider(uid: _uid, token: _token))
            .status,
        PasswordResetConfirmStatus.success,
      );
    });

    test('sets status to failure with message on error', () async {
      when(
        () => repository.confirmPasswordReset(
          uid: any(named: 'uid'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ValidationFailure('Token inválido ou expirado.')),
      );

      final container = makeContainer();
      final notifier = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token).notifier,
      );

      notifier.dispatch(const NewPasswordChanged('NewSecure!456'));
      notifier.dispatch(const ConfirmPasswordChanged('NewSecure!456'));
      notifier.dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(
        passwordResetConfirmProvider(uid: _uid, token: _token),
      );
      expect(state.status, PasswordResetConfirmStatus.failure);
      expect(state.message, 'Token inválido ou expirado.');
    });
  });
}
