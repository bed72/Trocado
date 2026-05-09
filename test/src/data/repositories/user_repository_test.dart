import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
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

  setUp(() {
    client = MockHttpClient();
    final userDataSource = RemoteUserDataSource(client: client);
    repository = UserRepository(userDataSource: userDataSource);

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

  group('purge', () {
    const email = 'jane@trocado.app';
    const password = 'MyPassword!456';

    test(
      'returns Right(null) when POST /api/v1/me/purge succeeds with email and password body',
      () async {
        when(
          () => client.post(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(<String, dynamic>{}));

        final data = await repository.purge(email: email, password: password);

        expect(data.isRight, isTrue);
        verify(
          () => client.post(
            parameter: any(
              named: 'parameter',
              that: predicate<Requests>(
                (r) =>
                    r.path == '/api/v1/me/purge' &&
                    r.body?['email'] == email &&
                    r.body?['password'] == password,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('returns Left(NetworkFailure) on network error', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkFailureJson));

      final data = await repository.purge(email: email, password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(NotFoundFailure) when POST returns 404', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_notFoundFailureJson));

      final data = await repository.purge(email: email, password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(ServerFailure) when POST returns 5xx', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_meFailureJson));

      final data = await repository.purge(email: email, password: password);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test(
      'returns Left(ValidationFailure) with backend message on validation error',
      () async {
        const failureJson = {
          'errors': [
            {'code': 'invalid', 'field': null, 'message': 'Senha incorreta.'},
          ],
        };

        when(
          () => client.post(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Left(failureJson));

        final data = await repository.purge(email: email, password: password);

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        expect((data.left as ValidationFailure).message, 'Senha incorreta.');
      },
    );
  });
}
