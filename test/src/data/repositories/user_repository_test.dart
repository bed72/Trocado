import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_user_data_source.dart';

import '../../../mocks/mocks.dart';

const _meSuccessJson = {
  'id': 1,
  'name': 'Jane Doe',
  'email': 'jane@trocado.app',
};

const _meFailureJson = {
  'errors': [
    {
      'code': 'server_error',
      'message': 'Unauthorized',
      'field': 'non_field_errors',
    },
  ],
};

const _networkFailureJson = {
  'errors': [
    {
      'code': 'network_error',
      'field': 'non_field_errors',
      'message': 'Sem conexão com o servidor.',
    },
  ],
};

const _notFoundFailureJson = {
  'errors': [
    {
      'code': 'not_found',
      'field': 'non_field_errors',
      'message': 'Recurso não encontrado.',
    },
  ],
};

void main() {
  late IHttpClient client;
  late IUserRepository repository;
  late ILocalTokenDataSource tokenDataSource;

  setUp(() {
    client = MockHttpClient();
    tokenDataSource = MockTokenDataSource();
    final userDataSource = RemoteUserDataSource(client: client);
    repository = UserRepository(
      userDataSource: userDataSource,
      tokenDataSource: tokenDataSource,
    );

    when(() => tokenDataSource.get()).thenAnswer(
      (_) async => (access: 'access-token', refresh: 'refresh-token'),
    );

    registerFallbackValue(const Requests('/'));
  });

  group('me', () {
    test('returns Right with UserModel on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_meSuccessJson));

      final data = await repository.me();

      expect(data.isRight, isTrue);
      expect(
        data.right,
        const UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe'),
      );
    });

    test('returns Left with Failure on API error', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.me();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('delete', () {
    const password = 'MyPassword!456';

    test(
      'returns Right(null) when DELETE /api/v1/me succeeds with refresh and password body',
      () async {
        when(
          () => client.delete(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));

        final data = await repository.delete(password: password);

        expect(data.isRight, isTrue);
        verify(
          () => client.delete(
            parameter: any(
              named: 'parameter',
              that: predicate<Requests>(
                (r) =>
                    r.path == '/api/v1/me' &&
                    r.body?['refresh'] == 'refresh-token' &&
                    r.body?['password'] == password,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'returns Left(UnknownFailure) when refresh token is unavailable',
      () async {
        when(
          () => tokenDataSource.get(),
        ).thenAnswer((_) async => (access: 'access-token', refresh: null));

        final data = await repository.delete(password: password);

        expect(data.isLeft, isTrue);
        expect(data.left, isA<UnknownFailure>());
        verifyNever(() => client.delete(parameter: any(named: 'parameter')));
      },
    );

    test('returns Left(NetworkFailure) on network error', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkFailureJson));

      final data = await repository.delete(password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(NotFoundFailure) when DELETE returns 404', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_notFoundFailureJson));

      final data = await repository.delete(password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(ServerFailure) when DELETE returns 5xx', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.delete(password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test(
      'returns Left(ValidationFailure) with backend message on invalid credentials',
      () async {
        const failureJson = {
          'errors': [
            {
              'code': 'invalid_credentials',
              'field': 'password',
              'message': 'Invalid credentials.',
            },
          ],
        };

        when(
          () => client.delete(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Left(failureJson));

        final data = await repository.delete(password: password);

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        expect(
          (data.left as ValidationFailure).message,
          'Invalid credentials.',
        );
      },
    );
  });

  group('updateName', () {
    const name = 'Jane Smith';

    test(
      'returns Right(UserModel) and sends only the name in the body',
      () async {
        when(
          () => client.patch(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(_meSuccessJson));

        final data = await repository.updateName(name: name);

        expect(data.isRight, isTrue);
        expect(
          data.right,
          const UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe'),
        );
        verify(
          () => client.patch(
            parameter: any(
              named: 'parameter',
              that: predicate<Requests>(
                (r) =>
                    r.path == '/api/v1/me' &&
                    r.body?['name'] == name &&
                    !(r.body?.containsKey('current_password') ?? false) &&
                    !(r.body?.containsKey('new_password') ?? false),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('returns Left(NetworkFailure) on network error', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkFailureJson));

      final data = await repository.updateName(name: name);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(NotFoundFailure) when PATCH returns 404', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_notFoundFailureJson));

      final data = await repository.updateName(name: name);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(ServerFailure) when PATCH returns 5xx', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.updateName(name: name);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test(
      'returns Left(ValidationFailure) with backend message on validation errors',
      () async {
        const failureJson = {
          'errors': [
            {
              'code': 'validation_error',
              'field': 'name',
              'message': 'Nome inválido.',
            },
          ],
        };

        when(
          () => client.patch(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Left(failureJson));

        final data = await repository.updateName(name: name);

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        expect((data.left as ValidationFailure).message, 'Nome inválido.');
      },
    );
  });

  group('updatePassword', () {
    const newPassword = 'NewSecure!456';
    const currentPassword = 'OldPassword!123';

    test(
      'returns Right(UserModel) and sends current and new password without name',
      () async {
        when(
          () => client.patch(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(_meSuccessJson));

        final data = await repository.updatePassword(
          newPassword: newPassword,
          currentPassword: currentPassword,
        );

        expect(data.isRight, isTrue);
        expect(
          data.right,
          const UserModel(id: 1, email: 'jane@trocado.app', name: 'Jane Doe'),
        );
        verify(
          () => client.patch(
            parameter: any(
              named: 'parameter',
              that: predicate<Requests>(
                (r) =>
                    r.path == '/api/v1/me' &&
                    r.body?['current_password'] == currentPassword &&
                    r.body?['new_password'] == newPassword &&
                    !(r.body?.containsKey('name') ?? false),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('returns Left(NetworkFailure) on network error', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkFailureJson));

      final data = await repository.updatePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(NotFoundFailure) when PATCH returns 404', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_notFoundFailureJson));

      final data = await repository.updatePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(ServerFailure) when PATCH returns 5xx', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.updatePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test(
      'returns Left(ValidationFailure) with backend message on invalid credentials',
      () async {
        const failureJson = {
          'errors': [
            {
              'code': 'invalid_credentials',
              'field': 'current_password',
              'message': 'Senha incorreta.',
            },
          ],
        };

        when(
          () => client.patch(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Left(failureJson));

        final data = await repository.updatePassword(
          newPassword: newPassword,
          currentPassword: currentPassword,
        );

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        expect((data.left as ValidationFailure).message, 'Senha incorreta.');
      },
    );
  });
}
