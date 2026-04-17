import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/data/repositories/budget_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_budget_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'id': 1,
  'value': '1000.00',
  'start_date': '2026-03-01',
  'end_date': '2026-03-31',
  'description': 'March budget',
};

const _activeSuccessJson = {
  'id': 35,
  'value': '18000.00',
  'start_date': '2026-04-01',
  'end_date': '2026-04-30',
  'description': 'Orçamento de Abril',
  'total_spent': '120.00',
  'remaining': '17880.00',
};

const _startDate = 1740787200000; // 2026-03-01 UTC
const _endDate = 1743379200000; // 2026-03-31 UTC

void main() {
  late IHttpClient client;
  late IBudgetRepository repository;

  setUp(() {
    client = MockHttpClient();
    repository = BudgetRepository(
      dataSource: RemoteBudgetDataSource(client: client),
    );

    registerFallbackValue(const Requests('/'));
  });

  group('create', () {
    test('returns Right with BudgetModel on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right(_successJson),
      );

      final data = await repository.create(
        value: 100000,
        startDate: _startDate,
        endDate: _endDate,
        description: 'March budget',
      );

      expect(data.isRight, isTrue);
      expect(data.right.id, 1);
      expect(data.right.value, 100000);
      expect(data.right.description, 'March budget');
    });

    test('converts decimal value to cents correctly', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'id': 2,
          'value': '85.50',
          'start_date': '2026-03-01',
          'end_date': '2026-03-31',
          'description': 'Test',
        }),
      );

      final data = await repository.create(
        value: 8550,
        startDate: _startDate,
        endDate: _endDate,
        description: 'Test',
      );

      expect(data.isRight, isTrue);
      expect(data.right.value, 8550);
    });

    test('returns Left ValidationFailure on 400 error', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'value',
              'code': 'invalid',
              'message': 'Ensure this value is greater than 0.',
            },
          ],
        }),
      );

      final data = await repository.create(
        value: 0,
        startDate: _startDate,
        endDate: _endDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Ensure this value is greater than 0.');
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

      final data = await repository.create(
        value: 100000,
        startDate: _startDate,
        endDate: _endDate,
        description: 'March budget',
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

      final data = await repository.create(
        value: 100000,
        startDate: _startDate,
        endDate: _endDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('findActive', () {
    test('returns Right with ActiveBudgetModel on success', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right(_activeSuccessJson),
      );

      final data = await repository.findActive();

      expect(data.isRight, isTrue);
      expect(data.right, isA<ActiveBudgetModel?>());
      expect(data.right!.id, 35);
      expect(data.right!.value, 1800000);
      expect(data.right!.totalSpent, 12000);
      expect(data.right!.remaining, 1788000);
    });

    test('returns Right(null) on 404 — no active budget', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'not_found',
              'field': 'non_field_errors',
              'message': 'No active budget found.',
            },
          ],
        }),
      );

      final data = await repository.findActive();

      expect(data.isRight, isTrue);
      expect(data.right, isNull);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });
}
