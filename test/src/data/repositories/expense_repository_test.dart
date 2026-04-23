import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_category.dart';
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'id': 1,
  'value': '85.50',
  'date': '2026-03-15',
  'category': 'food',
  'description': 'Mercado',
  'created_at': '2026-03-15T11:45:03.220605-03:00',
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
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

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
          'category': 'housing',
          'description': 'Aluguel',
          'created_at': '2026-03-15T11:45:03.220605-03:00',
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
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

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

    test('maps category string to ExpenseCategory enum', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isRight, isTrue);
      expect(data.right.category, ExpenseCategory.food);
    });

    test('maps unknown category string to ExpenseCategory.unknown', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'id': 5,
          'value': '10.00',
          'date': '2026-03-15',
          'category': 'travel',
          'description': 'Uber',
          'created_at': '2026-03-15T11:45:03.220605-03:00',
        }),
      );

      final data = await repository.create(
        value: 1000,
        date: _date,
        description: 'Uber',
      );

      expect(data.isRight, isTrue);
      expect(data.right.category, ExpenseCategory.unknown);
    });

    test('converts createdAt ISO string to milliseconds', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isRight, isTrue);
      expect(
        data.right.createdAt,
        DateTime.parse(
          '2026-03-15T11:45:03.220605-03:00',
        ).millisecondsSinceEpoch,
      );
    });
  });

  group('findRecent', () {
    const page = {
      'next': 'http://api/expenses?cursor=abc',
      'previous': null,
      'results': [
        {
          'id': 129,
          'value': '85.50',
          'date': '2026-04-15',
          'category': 'food',
          'description': 'Cafezinho',
          'created_at': '2026-04-22T11:45:03.220605-03:00',
        },
        {
          'id': 112,
          'value': '38.91',
          'date': '2026-04-30',
          'category': 'health',
          'description': 'Farmácia',
          'created_at': '2026-04-22T11:29:22.128274-03:00',
        },
        {
          'id': 111,
          'value': '236.66',
          'date': '2026-04-28',
          'category': 'shopping',
          'description': 'Arezzo',
          'created_at': '2026-04-22T11:29:22.126006-03:00',
        },
        {
          'id': 110,
          'value': '164.00',
          'date': '2026-04-26',
          'category': 'food',
          'description': 'Pão de Açúcar',
          'created_at': '2026-04-22T11:29:22.123672-03:00',
        },
        {
          'id': 109,
          'value': '19.24',
          'date': '2026-04-25',
          'category': 'transport',
          'description': 'Estacionamento',
          'created_at': '2026-04-22T11:29:22.121206-03:00',
        },
      ],
    };

    test('returns Right with at most limit items preserving order', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final data = await repository.findRecent(limit: 4);

      expect(data.isRight, isTrue);
      expect(data.right, hasLength(4));
      expect(data.right.first.id, 129);
      expect(data.right.first.description, 'Cafezinho');
      expect(data.right.last.id, 110);
    });

    test('returns Right with actual length when fewer than limit', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 1,
              'value': '10.00',
              'date': '2026-04-15',
              'category': 'food',
              'description': 'Lanche',
              'created_at': '2026-04-15T12:00:00Z',
            },
          ],
        }),
      );

      final data = await repository.findRecent(limit: 4);

      expect(data.isRight, isTrue);
      expect(data.right, hasLength(1));
    });

    test('returns Right with empty list when results is empty', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async =>
            const Right({'next': null, 'previous': null, 'results': []}),
      );

      final data = await repository.findRecent();

      expect(data.isRight, isTrue);
      expect(data.right, isEmpty);
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

      final data = await repository.findRecent();

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

      final data = await repository.findRecent();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure on not found error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'not_found',
              'field': 'non_field_errors',
              'message': 'Not found',
            },
          ],
        }),
      );

      final data = await repository.findRecent();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {'code': 'invalid', 'field': 'limit', 'message': 'Invalid limit.'},
          ],
        }),
      );

      final data = await repository.findRecent();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid limit.');
    });
  });

  group('findAll', () {
    const page = {
      'next': 'http://api/v1/expenses?cursor=NEXT123',
      'previous': null,
      'results': [
        {
          'id': 129,
          'value': '85.50',
          'date': '2026-04-15',
          'category': 'food',
          'description': 'Cafezinho',
          'created_at': '2026-04-22T11:45:03.220605-03:00',
        },
        {
          'id': 112,
          'value': '38.91',
          'date': '2026-04-30',
          'category': 'health',
          'description': 'Farmácia',
          'created_at': '2026-04-22T11:29:22.128274-03:00',
        },
        {
          'id': 111,
          'value': '236.66',
          'date': '2026-04-28',
          'category': 'shopping',
          'description': 'Arezzo',
          'created_at': '2026-04-22T11:29:22.126006-03:00',
        },
      ],
    };

    test(
      'invokes GET without any query suffix on the first page',
      () async {
        when(
          () => client.get(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(page));

        await repository.findAll();

        final captured = verify(
          () => client.get(parameter: captureAny(named: 'parameter')),
        ).captured.single as Requests;

        expect(captured.path, '/api/v1/expenses');
        expect(captured.query, isNull);
      },
    );

    test('embeds cursor into path on subsequent pages', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      await repository.findAll(cursor: 'ABC');

      final captured = verify(
        () => client.get(parameter: captureAny(named: 'parameter')),
      ).captured.single as Requests;

      expect(captured.path, '/api/v1/expenses?cursor=ABC');
      expect(captured.query, isNull);
    });

    test('embeds RQL fragments and ordering when filter is set', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final filter = ExpenseFilterModel(
        category: ExpenseCategory.food,
        minValue: 10000,
        ordering: ExpenseOrdering.valueDesc,
      );

      await repository.findAll(filter: filter);

      final captured = verify(
        () => client.get(parameter: captureAny(named: 'parameter')),
      ).captured.single as Requests;

      expect(
        captured.path,
        '/api/v1/expenses?'
        'eq(category,food)'
        '&ge(value,100.00)'
        '&ordering=-value'
        '&page_size=20',
      );
      expect(captured.query, isNull);
    });

    test('appends cursor after filter fragments when both are set', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategory.food,
      );

      await repository.findAll(filter: filter, cursor: 'NEXT');

      final captured = verify(
        () => client.get(parameter: captureAny(named: 'parameter')),
      ).captured.single as Requests;

      expect(captured.path, endsWith('&cursor=NEXT'));
      expect(captured.path, contains('eq(category,food)'));
    });

    test('returns Right with mapped page model on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final data = await repository.findAll();

      expect(data.isRight, isTrue);
      expect(data.right.expenses, hasLength(3));
      expect(data.right.expenses.first.id, 129);
      expect(data.right.expenses.first.category, ExpenseCategory.food);
      expect(data.right.nextCursor, 'NEXT123');
      expect(data.right.previousCursor, isNull);
    });

    test('returns Right with empty page when results is empty', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async =>
            const Right({'next': null, 'previous': null, 'results': []}),
      );

      final data = await repository.findAll();

      expect(data.isRight, isTrue);
      expect(data.right.expenses, isEmpty);
      expect(data.right.nextCursor, isNull);
      expect(data.right.previousCursor, isNull);
    });

    test(
      'returns Right with null cursor when next url has no cursor param',
      () async {
        when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Right({
            'next': 'http://api/v1/expenses',
            'previous': null,
            'results': [],
          }),
        );

        final data = await repository.findAll();

        expect(data.isRight, isTrue);
        expect(data.right.nextCursor, isNull);
      },
    );

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

      final data = await repository.findAll();

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

      final data = await repository.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure on not_found code', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'not_found',
              'field': 'non_field_errors',
              'message': 'Not found',
            },
          ],
        }),
      );

      final data = await repository.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'invalid',
              'field': 'cursor',
              'message': 'Invalid cursor.',
            },
          ],
        }),
      );

      final data = await repository.findAll(cursor: 'BROKEN');

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid cursor.');
    });
  });
}
