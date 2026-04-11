import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IHttpClient client;
  late AuthenticationRepository repository;

  setUp(() {
    client = MockHttpClient();
    final dataSource = RemoteAuthenticationDataSource(client: client);
    repository = AuthenticationRepository(dataSource: dataSource);

    registerFallbackValue(const Requests('/'));
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
}
