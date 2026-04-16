import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'id': 1,
  'value': '85.50',
  'date': '2026-03-15',
  'description': 'Mercado',
};

final _date = DateTime.parse('2026-03-15').millisecondsSinceEpoch;

void main() {
  late IHttpClient client;
  late IExpenseRepository repository;

  setUp(() {
    client = MockHttpClient();
    repository = ExpenseRepository(
      dataSource: RemoteExpenseDataSource(client: client),
    );

    registerFallbackValue(const Requests('/'));
  });

  group('create', () {
    test('returns Right with ExpenseModel on success', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right(_successJson),
      );

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isRight, isTrue);
      expect(data.right.id, 1);
      expect(data.right.value, 8550);
      expect(data.right.description, 'Mercado');
    });

    test('converts decimal value to cents correctly', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'id': 2,
          'value': '100.00',
          'date': '2026-03-15',
          'description': 'Aluguel',
        }),
      );

      final data = await repository.create(
        value: 10000,
        date: _date,
        description: 'Aluguel',
      );

      expect(data.isRight, isTrue);
      expect(data.right.value, 10000);
    });

    test('converts date string to milliseconds correctly', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right(_successJson),
      );

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isRight, isTrue);
      expect(data.right.date, _date);
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
        date: _date,
        description: 'Mercado',
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
        value: 8550,
        date: _date,
        description: 'Mercado',
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
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });
}
