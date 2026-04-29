import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/repositories/interface_user_repository.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
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

void main() {
  late IHttpClient client;
  late IUserRepository repository;

  setUp(() {
    client = MockHttpClient();
    final dataSource = RemoteUserDataSource(client: client);
    repository = UserRepository(dataSource: dataSource);

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
}
