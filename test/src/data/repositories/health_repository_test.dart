import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/health_repository.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_health_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'data': {
    'status': 'ok',
    'version': 1,
    'components': {
      'db': 'ok',
      'cache': 'ok',
      'queue': {'depth': 0, 'warning': false},
      'worker': {'status': 'ok', 'heartbeat_age_seconds': 5.94},
    },
  },
};

const _unhealthyJson = {
  'data': {'status': 'degraded', 'version': 1},
};

const _failureJson = {
  'errors': [
    {
      'code': 'server_error',
      'field': 'non_field_errors',
      'message': 'Internal server error',
    },
  ],
};

void main() {
  late IHttpClient client;
  late IHealthRepository repository;

  setUp(() {
    client = MockHttpClient();
    repository = HealthRepository(
      dataSource: RemoteHealthDataSource(client: client),
    );

    registerFallbackValue(const Requests('/'));
  });

  group('check', () {
    test('returns Right(true) when status is ok', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.check();

      expect(data.isRight, isTrue);
      expect(data.right, isTrue);
    });

    test('returns Right(false) when status is not ok', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_unhealthyJson));

      final data = await repository.check();

      expect(data.right, isFalse);
      expect(data.isRight, isTrue);
    });

    test('returns Left ServerFailure on server error', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_failureJson));

      final data = await repository.check();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.check();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });
  });
}
