import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

import '../../../mocks/mocks.dart';

const _signUpSuccessJson = {
  'data': {'access': 'access-token', 'refresh': 'refresh-token'},
};

void main() {
  late IHttpClient client;
  late IAuthenticationRepository repository;
  late ILocalTokenDataSource tokenDataSource;
  late INotificationRepository notificationRepository;
  late IRemoteAuthenticationDataSource authenticationDataSource;

  setUp(() {
    client = MockHttpClient();
    tokenDataSource = MockTokenDataSource();
    notificationRepository = MockNotificationRepository();
    authenticationDataSource = RemoteAuthenticationDataSource(client: client);
    repository = AuthenticationRepository(
      tokenDataSource: tokenDataSource,
      notificationRepository: notificationRepository,
      authenticationDataSource: authenticationDataSource,
    );

    registerFallbackValue(const Requests('/'));

    when(
      () => notificationRepository.revokeToken(),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => tokenDataSource.save(
        access: any(named: 'access'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer((_) async {});
  });

  group('signIn', () {
    test('returns Right with AuthenticationModel on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {'access': 'access-token', 'refresh': 'refresh-token'},
        }),
      );

      final data = await repository.signIn(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isRight, isTrue);
      expect(data.right.access, 'access-token');
      expect(data.right.refresh, 'refresh-token');
    });

    test('calls save with tokens on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {'access': 'access-token', 'refresh': 'refresh-token'},
        }),
      );

      await repository.signIn(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      verify(
        () => tokenDataSource.save(
          access: 'access-token',
          refresh: 'refresh-token',
        ),
      ).called(1);
    });

    test('does not call save on failure', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'non_field_errors',
              'code': 'no_active_account',
              'message': 'No active account found with the given credentials.',
            },
          ],
        }),
      );

      await repository.signIn(password: 'wrong', email: 'wrong@trocado.app');

      verifyNever(
        () => tokenDataSource.save(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        ),
      );
    });

    test('returns Left ValidationFailure on invalid credentials', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'non_field_errors',
              'code': 'no_active_account',
              'message': 'No active account found with the given credentials.',
            },
          ],
        }),
      );

      final data = await repository.signIn(
        password: 'wrong',
        email: 'wrong@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(
        data.left.message,
        'No active account found with the given credentials.',
      );
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.signIn(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await repository.signIn(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('signUp', () {
    test('returns Right with AuthenticationModel on success', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_signUpSuccessJson));

      final data = await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isRight, isTrue);
      expect(data.right.access, 'access-token');
      expect(data.right.refresh, 'refresh-token');
    });

    test('calls tokenDataSource.save with correct tokens on success', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_signUpSuccessJson));

      await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      verify(
        () => tokenDataSource.save(
          access: 'access-token',
          refresh: 'refresh-token',
        ),
      ).called(1);
    });

    test('does not call save on failure', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'unique',
              'field': 'email',
              'message': 'Este e-mail já está cadastrado.',
            },
          ],
        }),
      );

      await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      verifyNever(
        () => tokenDataSource.save(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        ),
      );
    });

    test('returns Left ValidationFailure on conflict', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'unique',
              'field': 'email',
              'message': 'Este e-mail já está cadastrado.',
            },
          ],
        }),
      );

      final data = await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Este e-mail já está cadastrado.');
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await repository.signUp(
        password: 'password123',
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('requestPasswordReset', () {
    test('returns Right on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {
            'detail':
                'If this email is registered, a reset link has been sent.',
          },
        }),
      );

      final data = await repository.requestPasswordReset(
        email: 'jane@trocado.app',
      );

      expect(data.isRight, isTrue);
    });

    test('does not call tokenDataSource.save on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {
            'detail':
                'If this email is registered, a reset link has been sent.',
          },
        }),
      );

      await repository.requestPasswordReset(email: 'jane@trocado.app');

      verifyNever(
        () => tokenDataSource.save(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        ),
      );
    });

    test('returns Left ValidationFailure on API error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'email',
              'code': 'invalid',
              'message': 'Não foi possível enviar o e-mail.',
            },
          ],
        }),
      );

      final data = await repository.requestPasswordReset(
        email: 'invalid@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Não foi possível enviar o e-mail.');
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.requestPasswordReset(
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await repository.requestPasswordReset(
        email: 'jane@trocado.app',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('checkSession', () {
    test('returns Left when no tokens in storage', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: null, refresh: null));

      final data = await repository.checkSession();

      expect(data.isLeft, isTrue);
    });

    test('returns Right when access token is valid', () async {
      when(() => tokenDataSource.get()).thenAnswer(
        (_) async => (access: 'valid_access', refresh: 'refresh_token'),
      );
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await repository.checkSession();

      expect(data.isRight, isTrue);
    });

    test(
      'refreshes and returns Right when access expired but refresh valid',
      () async {
        when(() => tokenDataSource.get()).thenAnswer(
          (_) async => (access: 'expired_access', refresh: 'valid_refresh'),
        );

        int callCount = 0;
        when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount == 1) {
            return const Left({
              'errors': [
                {
                  'code': 'token_not_valid',
                  'field': 'non_field_errors',
                  'message': 'Token is invalid or expired.',
                },
              ],
            });
          }

          return const Right({
            'data': {'access': 'new_access', 'refresh': 'new_refresh'},
          });
        });

        final data = await repository.checkSession();

        expect(data.isRight, isTrue);
        verify(
          () => tokenDataSource.save(
            access: 'new_access',
            refresh: 'new_refresh',
          ),
        ).called(1);
      },
    );

    test('returns Left when access is expired and refresh is null', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'expired_access', refresh: null));
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'token_not_valid',
              'field': 'non_field_errors',
              'message': 'Token is invalid or expired.',
            },
          ],
        }),
      );

      final data = await repository.checkSession();

      expect(data.isLeft, isTrue);
      verifyNever(() => tokenDataSource.clear());
    });

    test(
      'clears tokens and returns Left when both tokens are expired',
      () async {
        when(() => tokenDataSource.get()).thenAnswer(
          (_) async => (access: 'expired_access', refresh: 'expired_refresh'),
        );
        when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Left({
            'errors': [
              {
                'code': 'token_not_valid',
                'field': 'non_field_errors',
                'message': 'Token is invalid or expired.',
              },
            ],
          }),
        );
        when(() => tokenDataSource.clear()).thenAnswer((_) async {});

        final data = await repository.checkSession();

        expect(data.isLeft, isTrue);
        verify(() => tokenDataSource.clear()).called(1);
      },
    );
  });

  group('confirmPasswordReset', () {
    test('returns Right on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {'detail': 'Password has been reset successfully.'},
        }),
      );

      final data = await repository.confirmPasswordReset(
        uid: 'Mw',
        token: 'bm7gkj-1a2b3c4d',
        newPassword: 'NewSecure!456',
      );

      expect(data.isRight, isTrue);
    });

    test('does not call tokenDataSource.save on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {'detail': 'Password has been reset successfully.'},
        }),
      );

      await repository.confirmPasswordReset(
        uid: 'Mw',
        token: 'bm7gkj-1a2b3c4d',
        newPassword: 'NewSecure!456',
      );

      verifyNever(
        () => tokenDataSource.save(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        ),
      );
    });

    test('returns Left ValidationFailure on API error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'token',
              'code': 'invalid',
              'message': 'Token inválido ou expirado.',
            },
          ],
        }),
      );

      final data = await repository.confirmPasswordReset(
        uid: 'Mw',
        token: 'expired-token',
        newPassword: 'NewSecure!456',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Token inválido ou expirado.');
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.confirmPasswordReset(
        uid: 'Mw',
        token: 'bm7gkj-1a2b3c4d',
        newPassword: 'NewSecure!456',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await repository.confirmPasswordReset(
        uid: 'Mw',
        token: 'bm7gkj-1a2b3c4d',
        newPassword: 'NewSecure!456',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('logout', () {
    setUp(() {
      when(() => tokenDataSource.clear()).thenAnswer((_) async {});
    });

    test('returns Right and clears tokens on success', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));

      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await repository.logout();

      expect(data.isRight, isTrue);
      verify(() => tokenDataSource.clear()).called(1);
    });

    test(
      'clears tokens and returns Right when refresh token is null',
      () async {
        when(
          () => tokenDataSource.get(),
        ).thenAnswer((_) async => (access: 'access', refresh: null));

        final data = await repository.logout();

        expect(data.isRight, isTrue);
        verify(() => tokenDataSource.clear()).called(1);
        verifyNever(() => client.post(parameter: any(named: 'parameter')));
      },
    );

    test(
      'returns Left ValidationFailure and does not clear tokens on API error',
      () async {
        when(
          () => tokenDataSource.get(),
        ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));

        when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Left({
            'errors': [
              {'field': null, 'code': 'invalid', 'message': 'Token inválido.'},
            ],
          }),
        );

        final data = await repository.logout();

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        verifyNever(() => tokenDataSource.clear());
      },
    );

    test('returns Left NetworkFailure on network error', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));

      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'field': 'non_field_errors',
              'message': 'Network error',
            },
          ],
        }),
      );

      final data = await repository.logout();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
      verifyNever(() => tokenDataSource.clear());
    });

    test('calls revokeToken once on successful logout', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      await repository.logout();

      verify(() => notificationRepository.revokeToken()).called(1);
    });

    test('calls revokeToken once when refresh token is null', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: null));

      await repository.logout();

      verify(() => notificationRepository.revokeToken()).called(1);
    });

    test('calls revokeToken once even when signOut returns error', () async {
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {'field': null, 'code': 'invalid', 'message': 'Token inválido.'},
          ],
        }),
      );

      await repository.logout();

      verify(() => notificationRepository.revokeToken()).called(1);
    });

    test('slow revokeToken does not block logout return', () async {
      final completer = Completer<Either<Failure, void>>();
      when(
        () => notificationRepository.revokeToken(),
      ).thenAnswer((_) => completer.future);
      when(
        () => tokenDataSource.get(),
      ).thenAnswer((_) async => (access: 'access', refresh: 'refresh-token'));
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await repository.logout();

      expect(data.isRight, isTrue);
      expect(completer.isCompleted, isFalse);
      verify(() => notificationRepository.revokeToken()).called(1);

      completer.complete(const Right(null));
    });
  });
}
