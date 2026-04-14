import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/core/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

import '../../../mocks/mocks.dart';

const _signUpSuccessJson = {
  'access': 'access-token',
  'refresh': 'refresh-token',
  'user': {
    'id': 42,
    'email': 'jane@trocado.app',
    'name': 'jane',
    'avatar': null,
  },
};

void main() {
  late IHttpClient client;
  late IAuthenticationRepository repository;
  late ILocalTokenDataSource tokenDataSource;
  late IRemoteAuthenticationDataSource authenticationDataSource;

  setUp(() {
    client = MockHttpClient();
    tokenDataSource = MockTokenDataSource();
    authenticationDataSource = RemoteAuthenticationDataSource(client: client);
    repository = AuthenticationRepository(
      tokenDataSource: tokenDataSource,
      authenticationDataSource: authenticationDataSource,
    );

    registerFallbackValue(const Requests('/'));

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
        (_) async =>
            const Right({'access': 'access-token', 'refresh': 'refresh-token'}),
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
        (_) async =>
            const Right({'access': 'access-token', 'refresh': 'refresh-token'}),
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
    test('returns Right with SignUpModel on success', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_signUpSuccessJson));

      final data = await repository.signUp(
        email: 'jane@trocado.app',
        password: 'password123',
      );

      expect(data.isRight, isTrue);
      expect(data.right.access, 'access-token');
      expect(data.right.refresh, 'refresh-token');
      expect(data.right.user.id, 42);
      expect(data.right.user.email, 'jane@trocado.app');
      expect(data.right.user.name, 'jane');
    });

    test('calls tokenDataSource.save with correct tokens on success', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_signUpSuccessJson));

      await repository.signUp(
        email: 'jane@trocado.app',
        password: 'password123',
      );

      verify(
        () => tokenDataSource.save(
          access: 'access-token',
          refresh: 'refresh-token',
        ),
      ).called(1);
    });

    test('does not call save on failure', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'email',
              'code': 'unique',
              'message': 'Este e-mail já está cadastrado.',
            },
          ],
        }),
      );

      await repository.signUp(
        email: 'jane@trocado.app',
        password: 'password123',
      );

      verifyNever(
        () => tokenDataSource.save(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        ),
      );
    });

    test('returns Left ValidationFailure on conflict', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'email',
              'code': 'unique',
              'message': 'Este e-mail já está cadastrado.',
            },
          ],
        }),
      );

      final data = await repository.signUp(
        email: 'jane@trocado.app',
        password: 'password123',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Este e-mail já está cadastrado.');
    });

    test('returns Left NetworkFailure on network error', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer(
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

      final data = await repository.signUp(
        email: 'jane@trocado.app',
        password: 'password123',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer(
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
        email: 'jane@trocado.app',
        password: 'password123',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('requestPasswordReset', () {
    test('returns Right on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'detail':
              'If this email is registered, a reset link has been sent.',
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
          'detail':
              'If this email is registered, a reset link has been sent.',
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
              'field': 'non_field_errors',
              'message': 'Network error',
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

  group('confirmPasswordReset', () {
    test('returns Right on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'detail': 'Password has been reset successfully.',
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
          'detail': 'Password has been reset successfully.',
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
              'field': 'non_field_errors',
              'message': 'Network error',
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
}
