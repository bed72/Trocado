import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/repositories/expense_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'data': {
    'id': 1,
    'value': '85.50',
    'date': '2026-03-15',
    'category': 'food',
    'description': 'Mercado',
    'created_at': '2026-03-15T11:45:03.220605-03:00',
  },
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
          'data': {
            'id': 2,
            'value': '100.00',
            'date': '2026-03-15',
            'category': 'housing',
            'description': 'Aluguel',
            'created_at': '2026-03-15T11:45:03.220605-03:00',
          },
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

    test('maps category string to ExpenseCategoryEnum value', () async {
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isRight, isTrue);
      expect(data.right.category, ExpenseCategoryEnum.food);
    });

    test(
      'maps unknown category string to ExpenseCategoryEnum.unknown',
      () async {
        when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Right({
            'data': {
              'id': 5,
              'value': '10.00',
              'date': '2026-03-15',
              'category': 'travel',
              'description': 'Uber',
              'created_at': '2026-03-15T11:45:03.220605-03:00',
            },
          }),
        );

        final data = await repository.create(
          value: 1000,
          date: _date,
          description: 'Uber',
        );

        expect(data.isRight, isTrue);
        expect(data.right.category, ExpenseCategoryEnum.unknown);
      },
    );

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

    test('returns Left UnknownFailure when errors list is empty', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({'errors': <Map<String, dynamic>>[]}),
      );

      final data = await repository.create(
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<UnknownFailure>());
    });
  });

  group('findRecent', () {
    const page = {
      'data': [
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
      'links': {'next': 'http://api/expenses?cursor=abc'},
    };

    test('returns Right with at most limit items preserving order', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final data = await repository.findRecent(
        limit: 4,
        scope: FinancialScopeEnum.mine,
      );

      expect(data.isRight, isTrue);
      expect(data.right.last.id, 110);
      expect(data.right, hasLength(4));
      expect(data.right.first.id, 129);
      expect(data.right.first.description, 'Cafezinho');
    });

    test('returns Right with actual length when fewer than limit', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': [
            {
              'id': 1,
              'value': '10.00',
              'category': 'food',
              'date': '2026-04-15',
              'description': 'Lanche',
              'created_at': '2026-04-15T12:00:00Z',
            },
          ],
        }),
      );

      final data = await repository.findRecent(
        limit: 4,
        scope: FinancialScopeEnum.mine,
      );

      expect(data.isRight, isTrue);
      expect(data.right, hasLength(1));
    });

    test('returns Right with empty list when results is empty', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': <dynamic>[],
          'links': {'next': null},
        }),
      );

      final data = await repository.findRecent(scope: FinancialScopeEnum.mine);

      expect(data.right, isEmpty);
      expect(data.isRight, isTrue);
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

      final data = await repository.findRecent(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findRecent(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findRecent(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findRecent(scope: FinancialScopeEnum.mine);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid limit.');
    });

    test('uses /expenses/shared path when scope is couple', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': <dynamic>[],
          'links': {'next': null},
        }),
      );

      await repository.findRecent(scope: FinancialScopeEnum.couple);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses/shared');
    });
  });

  group('findAll', () {
    const page = {
      'data': [
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
      'links': {'next': 'http://api/v1/expenses?cursor=NEXT123'},
    };

    test('invokes GET without any query suffix on the first page', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      await repository.findAll(scope: FinancialScopeEnum.mine);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses');
      expect(captured.query, isNull);
    });

    test('embeds cursor into path on subsequent pages', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      await repository.findAll(cursor: 'ABC', scope: FinancialScopeEnum.mine);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses?cursor=ABC');
      expect(captured.query, isNull);
    });

    test('embeds RQL fragments when filter is set', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final filter = ExpenseFilterModel(
        category: ExpenseCategoryEnum.food,
        startDate: DateTime(2026, 3, 1).millisecondsSinceEpoch,
      );

      await repository.findAll(filter: filter, scope: FinancialScopeEnum.mine);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(
        captured.path,
        '/api/v1/expenses?'
        'eq(category,food)'
        '&ge(date,2026-03-01)'
        '&page_size=20',
      );
      expect(captured.query, isNull);
    });

    test('appends cursor after filter fragments when both are set', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategoryEnum.food,
      );

      await repository.findAll(
        filter: filter,
        cursor: 'NEXT',
        scope: FinancialScopeEnum.mine,
      );

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, endsWith('&cursor=NEXT'));
      expect(captured.path, contains('eq(category,food)'));
    });

    test('returns Right with mapped page model on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(page));

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isRight, isTrue);
      expect(data.right.nextCursor, 'NEXT123');
       expect(data.right.items, hasLength(3));
       expect(data.right.items.first.id, 129);
      expect(data.right.previousCursor, isNull);
       expect(data.right.items.first.category, ExpenseCategoryEnum.food);
    });

    test('returns Right with empty page when results is empty', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': <dynamic>[],
          'links': {'next': null},
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isRight, isTrue);
       expect(data.right.items, isEmpty);
      expect(data.right.nextCursor, isNull);
      expect(data.right.previousCursor, isNull);
    });

    test(
      'returns Right with null cursor when next url has no cursor param',
      () async {
        when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Right({
            'data': [],
            'links': {'next': 'http://api/v1/expenses'},
          }),
        );

        final data = await repository.findAll(scope: FinancialScopeEnum.mine);

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
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

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

      final data = await repository.findAll(
        cursor: 'BROKEN',
        scope: FinancialScopeEnum.mine,
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid cursor.');
    });

    test('uses /expenses/shared path when scope is couple', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': <dynamic>[],
          'links': {'next': null},
        }),
      );

      await repository.findAll(scope: FinancialScopeEnum.couple);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses/shared');
    });

    test(
      'uses /expenses/shared path with RQL when scope is couple and filter is set',
      () async {
        when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Right({
            'data': <dynamic>[],
            'links': {'next': null},
          }),
        );

        const filter = ExpenseFilterModel(category: ExpenseCategoryEnum.food);
        await repository.findAll(
          filter: filter,
          scope: FinancialScopeEnum.couple,
        );

        final captured =
            verify(
                  () => client.get(parameter: captureAny(named: 'parameter')),
                ).captured.single
                as Requests;

        expect(captured.path, startsWith('/api/v1/expenses/shared?'));
      },
    );
  });

  group('update', () {
    test('returns Right with ExpenseModel on 200', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.update(
        id: 1,
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.right.id, 1);
      expect(data.isRight, isTrue);
      expect(data.right.value, 8550);
      expect(data.right.description, 'Mercado');
    });

    test('sends PATCH to /api/v1/expenses/<id>', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.update(
        id: 132,
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      final captured =
          verify(
                () => client.patch(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses/132');
    });

    test('sends body serialized via ExpenseRequest', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.update(
        id: 1,
        value: 9230,
        date: _date,
        description: 'Mercado',
      );

      final captured =
          verify(
                () => client.patch(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.body, {
        'value': '92.30',
        'date': '2026-03-15',
        'description': 'Mercado',
      });
    });

    test('returns Left(ValidationFailure) on 400 with errors body', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'field': 'value',
              'code': 'validation_error',
              'message': 'Valor inválido.',
            },
          ],
        }),
      );

      final data = await repository.update(
        id: 1,
        value: 0,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Valor inválido.');
    });

    test('returns Left(NetworkFailure) on connectivity error', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.update(
        id: 1,
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left(ServerFailure) on 5xx', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'message': 'Server error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.update(
        id: 1,
        value: 8550,
        date: _date,
        description: 'Mercado',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('delete', () {
    test('returns Right(null) when 204 with empty body', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await repository.delete(id: 132);

      expect(data.isRight, isTrue);
    });

    test('sends DELETE to /api/v1/expenses/<id> with no body', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      await repository.delete(id: 132);

      final captured =
          verify(
                () => client.delete(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses/132');
      expect(captured.body, isNull);
    });

    test('returns Left(NotFoundFailure) on 404 with errors body', () async {
      when(() => client.delete(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.delete(id: 999);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left(NetworkFailure) on connectivity error', () async {
      when(() => client.delete(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.delete(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left UnknownFailure when errors list is empty', () async {
      when(() => client.delete(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({'errors': <Map<String, dynamic>>[]}),
      );

      final data = await repository.delete(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<UnknownFailure>());
    });
  });

  group('findById', () {
    const successJson = {
      'data': {
        'id': 132,
        'value': '85.50',
        'category': 'food',
        'date': '2026-03-15',
        'description': 'Mercado',
        'created_at': '2026-03-15T18:30:00-03:00',
      },
    };

    test('calls GET on /api/v1/expenses/<id>', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(successJson));

      await repository.findById(id: 132);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/expenses/132');
    });

    test('returns Right with ExpenseModel on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(successJson));

      final data = await repository.findById(id: 132);

      expect(data.right.id, 132);
      expect(data.isRight, isTrue);
      expect(data.right.value, 8550);
      expect(data.right.description, 'Mercado');
    });

    test('returns Left NotFoundFailure on 404', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'not_found',
              'message': 'Not found',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.findById(id: 999);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'message': 'Network',
              'code': 'network_error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.findById(id: 132);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });
  });
}
