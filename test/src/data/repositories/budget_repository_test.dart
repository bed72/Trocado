import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/repositories/budget_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_budget_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'id': 1,
  'value': '1000.00',
  'end_date': '2026-03-31',
  'start_date': '2026-03-01',
  'description': 'March budget',
};

const _activeSuccessJson = {
  'id': 35,
  'value': '18000.00',
  'remaining': '17880.00',
  'total_spent': '120.00',
  'end_date': '2026-04-30',
  'start_date': '2026-04-01',
  'description': 'Orçamento de Abril',
};

const _endDate = 1743379200000; // 2026-03-31 UTC
const _startDate = 1740787200000; // 2026-03-01 UTC

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
      when(
        () => client.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.create(
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.right.id, 1);
      expect(data.isRight, isTrue);
      expect(data.right.value, 100000);
      expect(data.right.description, 'March budget');
    });

    test('converts decimal value to cents correctly', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'id': 2,
          'value': '85.50',
          'description': 'Test',
          'end_date': '2026-03-31',
          'start_date': '2026-03-01',
        }),
      );

      final data = await repository.create(
        value: 8550,
        endDate: _endDate,
        description: 'Test',
        startDate: _startDate,
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
        endDate: _endDate,
        startDate: _startDate,
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
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.create(
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
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
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left UnknownFailure when errors list is empty', () async {
      when(() => client.post(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({'errors': <Map<String, dynamic>>[]}),
      );

      final data = await repository.create(
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<UnknownFailure>());
    });
  });

  group('findActive', () {
    test('returns Right with ActiveBudgetModel on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_activeSuccessJson));

      final data = await repository.findActive();

      expect(data.right!.id, 35);
      expect(data.isRight, isTrue);
      expect(data.right!.value, 1800000);
      expect(data.right!.totalSpent, 12000);
      expect(data.right!.remaining, 1788000);
      expect(data.right, isA<ActiveBudgetModel?>());
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

      expect(data.right, isNull);
      expect(data.isRight, isTrue);
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

  group('findAll', () {
    const pageJson = {
      'next': 'http://api.example.org/budgets/?cursor=NEXT',
      'previous': null,
      'results': [
        {
          'id': 9,
          'value': '1000.00',
          'remaining': '714.50',
          'total_spent': '285.50',
          'end_date': '2026-05-30',
          'start_date': '2026-05-01',
          'description': 'May budget',
          'created_at': '2026-05-02T17:58:42.119430-03:00',
        },
        {
          'id': 4,
          'value': '2200.00',
          'end_date': '2026-02-28',
          'remaining': '-1734.97',
          'total_spent': '3934.97',
          'start_date': '2026-02-01',
          'description': 'Fevereiro 2026',
          'created_at': '2026-02-02T17:34:21.517100-03:00',
        },
      ],
    };

    test(
      'calls GET on budgets endpoint without query when cursor is null',
      () async {
        when(
          () => client.get(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(pageJson));

        await repository.findAll();

        final captured =
            verify(
                  () => client.get(parameter: captureAny(named: 'parameter')),
                ).captured.single
                as Requests;

        expect(captured.query, isNull);
        expect(captured.path, '/api/v1/budgets');
      },
    );

    test(
      'calls GET with query {cursor: ABC} when cursor is provided',
      () async {
        when(
          () => client.get(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(pageJson));

        await repository.findAll(cursor: 'ABC');

        final captured =
            verify(
                  () => client.get(parameter: captureAny(named: 'parameter')),
                ).captured.single
                as Requests;

        expect(captured.path, '/api/v1/budgets');
        expect(captured.query, {'cursor': 'ABC'});
      },
    );

    test(
      'returns Right with BudgetsPageModel and extracted nextCursor',
      () async {
        when(
          () => client.get(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(pageJson));

        final data = await repository.findAll();

        expect(data.isRight, isTrue);
        expect(data.right.nextCursor, 'NEXT');
        expect(data.right.budgets, hasLength(2));
        expect(data.right.previousCursor, isNull);
        expect(data.right, isA<BudgetsPageModel>());
      },
    );

    test(
      'maps value, totalSpent, remaining to centavos including negative',
      () async {
        when(
          () => client.get(parameter: any(named: 'parameter')),
        ).thenAnswer((_) async => const Right(pageJson));

        final data = await repository.findAll();
        final overspent = data.right.budgets[1];

        expect(overspent.value, 220000);
        expect(overspent.totalSpent, 393497);
        expect(overspent.remaining, -173497);
      },
    );

    test('maps startDate, endDate to ms epoch from yyyy-MM-dd', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(pageJson));

      final data = await repository.findAll();
      final first = data.right.budgets.first;

      expect(
        first.startDate,
        DateTime.parse('2026-05-01').millisecondsSinceEpoch,
      );
      expect(
        first.endDate,
        DateTime.parse('2026-05-30').millisecondsSinceEpoch,
      );
    });

    test('maps createdAt to ms epoch from ISO 8601 with timezone', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(pageJson));

      final data = await repository.findAll();

      expect(
        data.right.budgets.first.createdAt,
        DateTime.parse(
          '2026-05-02T17:58:42.119430-03:00',
        ).millisecondsSinceEpoch,
      );
    });

    test(
      'extracts cursor even when next URL has multiple query params',
      () async {
        when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Right({
            'results': [],
            'previous': null,
            'next': 'http://api.example.org/budgets/?cursor=ABC&ordering=desc',
          }),
        );

        final data = await repository.findAll();

        expect(data.right.nextCursor, 'ABC');
      },
    );

    test('returns nextCursor null when next is null', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async =>
            const Right({'next': null, 'previous': null, 'results': []}),
      );

      final data = await repository.findAll();

      expect(data.right.budgets, isEmpty);
      expect(data.right.nextCursor, isNull);
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

    test(
      'returns Left ValidationFailure with message for unknown code',
      () async {
        when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
          (_) async => const Left({
            'errors': [
              {
                'code': 'something_weird',
                'field': 'non_field_errors',
                'message': 'Algo de errado.',
              },
            ],
          }),
        );

        final data = await repository.findAll();

        expect(data.isLeft, isTrue);
        expect(data.left, isA<ValidationFailure>());
        expect(data.left.message, 'Algo de errado.');
      },
    );
  });

  group('findById', () {
    test('calls GET on /api/v1/budgets/<id>', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.findById(id: 1);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/budgets/1');
    });

    test('returns Right with BudgetModel on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.findById(id: 1);

      expect(data.isRight, isTrue);
      expect(data.right.id, 1);
      expect(data.right.value, 100000);
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
              'code': 'network_error',
              'message': 'Network',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.findById(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });
  });

  group('update', () {
    test('calls PATCH on /api/v1/budgets/<id>', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.update(
        id: 1,
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      final captured =
          verify(
                () => client.patch(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/budgets/1');
      expect(captured.body, isNotNull);
    });

    test('returns Right with BudgetModel on success', () async {
      when(
        () => client.patch(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.update(
        id: 1,
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.right.id, 1);
      expect(data.isRight, isTrue);
      expect(data.right.value, 100000);
    });

    test('returns Left ValidationFailure on 400 with errors body', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {'code': 'invalid', 'field': 'value', 'message': 'Valor inválido.'},
          ],
        }),
      );

      final data = await repository.update(
        id: 1,
        value: -1,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Valor inválido.');
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.update(
        id: 1,
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on 5xx', () async {
      when(() => client.patch(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.update(
        id: 1,
        value: 100000,
        endDate: _endDate,
        startDate: _startDate,
        description: 'March budget',
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });
  });

  group('delete', () {
    test('calls DELETE on /api/v1/budgets/<id> with no body', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      await repository.delete(id: 1);

      final captured =
          verify(
                () => client.delete(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.body, isNull);
      expect(captured.path, '/api/v1/budgets/1');
    });

    test('returns Right(null) on 204 success with empty body', () async {
      when(
        () => client.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await repository.delete(id: 1);

      expect(data.isRight, isTrue);
    });

    test('returns Left NotFoundFailure on 404', () async {
      when(() => client.delete(parameter: any(named: 'parameter'))).thenAnswer(
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

      final data = await repository.delete(id: 999);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.delete(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network',
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
}
