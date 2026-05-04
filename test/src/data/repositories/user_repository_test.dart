import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_user_data_source.dart';

import '../../../mocks/mocks.dart';

const _meSuccessJson = {
  'id': 1,
  'email': 'jane@trocado.app',
  'name': 'Jane Doe',
};

const _meFailureJson = {
  'errors': [
    {
      'field': 'non_field_errors',
      'message': 'Unauthorized',
      'code': 'server_error',
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
      tokenDataSource: tokenDataSource,
      userDataSource: userDataSource,
    );

    when(
      () => tokenDataSource.get(),
    ).thenAnswer((_) async => (access: 'access-token', refresh: 'refresh-token'));

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

  group('deactivate', () {
    test(
      'returns Right(null) when DELETE /api/v1/me succeeds with refresh body',
      () async {
        when(
          () => client.delete(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));

        final data = await repository.deactivate();

        expect(data.isRight, isTrue);
        verify(
          () => client.delete(
            parameter: any(
              named: 'parameter',
              that: predicate<Requests>(
                (r) =>
                    r.path == '/api/v1/me' &&
                    r.body?['refresh'] == 'refresh-token',
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'returns Left(UnknownFailure) when refresh token is unavailable',
      () async {
        when(() => tokenDataSource.get()).thenAnswer(
          (_) async => (access: 'access-token', refresh: null),
        );

        final data = await repository.deactivate();

        expect(data.isLeft, isTrue);
        expect(data.left, isA<UnknownFailure>());
        verifyNever(() => client.delete(parameter: any(named: 'parameter')));
      },
    );

    test('returns Left(NetworkFailure) on network error', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkFailureJson));

      final data = await repository.deactivate();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(NotFoundFailure) when DELETE returns 404', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_notFoundFailureJson));

      final data = await repository.deactivate();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(ServerFailure) when DELETE returns 5xx', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.deactivate();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });
}
