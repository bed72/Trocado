import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expense_category.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_notifier.dart';

import '../../../mocks/mocks.dart';

const _first = [
  ExpenseModel(
    id: 1,
    value: 8550,
    date: 1744675200000,
    createdAt: 1745332903000,
    description: 'Cafezinho',
    category: ExpenseCategory.food,
  ),
  ExpenseModel(
    id: 2,
    value: 3891,
    date: 1745971200000,
    createdAt: 1745331562000,
    description: 'Farmácia',
    category: ExpenseCategory.health,
  ),
];

const _second = [
  ExpenseModel(
    id: 3,
    value: 2000,
    date: 1744500000000,
    createdAt: 1745330000000,
    description: 'Uber',
    category: ExpenseCategory.transport,
  ),
];

ProviderContainer _makeContainer({
  required IExpenseRepository repository,
  required IMoneyService moneyService,
}) {
  final container = ProviderContainer(
    overrides: [
      moneyServiceProvider.overrideWithValue(moneyService),
      expenseRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IExpenseRepository repository;

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockExpenseRepository();

    when(() => moneyService.format(any())).thenAnswer(
      (invocation) => 'R\$ ${invocation.positionalArguments.first}',
    );
  });

  group('build', () {
    test(
      'returns AsyncData with first page items and nextCursor on success',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => const Right(
            ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
        );
        final data = await container.read(expensesProvider.future);

        expect(data.items, hasLength(2));
        expect(data.items.map((item) => item.expense), equals(_first));
        expect(data.items.first.formattedValue, 'R\$ 85.5');
        expect(data.nextCursor, 'CUR1');
        expect(data.isLoadingMore, isFalse);
        expect(data.loadMoreFailure, isNull);
      },
    );

    test('calls findAll without cursor on first build', () async {
      when(
        () => repository.findAll(cursor: any(named: 'cursor')),
      ).thenAnswer((_) async => const Right(ExpensesPageModel()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      verify(() => repository.findAll(cursor: null)).called(1);
    });

    test(
      'emits AsyncError when repository returns Left(NetworkFailure)',
      () async {
        when(
          () => repository.findAll(cursor: any(named: 'cursor')),
        ).thenAnswer((_) async => const Left(NetworkFailure()));

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
        );
        container.listen(expensesProvider, (_, _) {});
        container.read(expensesProvider);

        await pumpEventQueue();

        expect(container.read(expensesProvider).hasError, isTrue);
        expect(container.read(expensesProvider).error, isA<NetworkFailure>());
      },
    );
  });

  group('loadMore', () {
    test('appends items and updates nextCursor on success', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(() => repository.findAll(cursor: 'CUR1')).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _second, nextCursor: 'CUR2'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).loadMore();

      final data = container.read(expensesProvider).value!;
      expect(
        data.items.map((item) => item.expense),
        equals([..._first, ..._second]),
      );
      expect(data.nextCursor, 'CUR2');
      expect(data.isLoadingMore, isFalse);
      expect(data.loadMoreFailure, isNull);
    });

    test('sets nextCursor to null at end of list', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(() => repository.findAll(cursor: 'CUR1')).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _second, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).loadMore();

      expect(container.read(expensesProvider).value!.nextCursor, isNull);
    });

    test('is a no-op when isLoadingMore is already true', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(() => repository.findAll(cursor: 'CUR1')).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _second, nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      final first = container.read(expensesProvider.notifier).loadMore();
      final second = container.read(expensesProvider.notifier).loadMore();

      await Future.wait([first, second]);

      verify(() => repository.findAll(cursor: 'CUR1')).called(1);
    });

    test('is a no-op when nextCursor is null', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _first, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).loadMore();

      verify(() => repository.findAll(cursor: null)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('preserves items and records failure on error', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.findAll(cursor: 'CUR1'),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).loadMore();

      final data = container.read(expensesProvider).value!;
      expect(data.items.map((item) => item.expense), equals(_first));
      expect(data.nextCursor, 'CUR1');
      expect(data.isLoadingMore, isFalse);
      expect(data.loadMoreFailure, isA<ServerFailure>());
    });

    test('clears failure and appends items on retry success', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      final responses = <Either<Failure, ExpensesPageModel>>[
        const Left(ServerFailure()),
        const Right(ExpensesPageModel(expenses: _second, nextCursor: null)),
      ];
      when(
        () => repository.findAll(cursor: 'CUR1'),
      ).thenAnswer((_) async => responses.removeAt(0));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).loadMore();
      await container.read(expensesProvider.notifier).loadMore();

      final data = container.read(expensesProvider).value!;
      expect(
        data.items.map((item) => item.expense),
        equals([..._first, ..._second]),
      );
      expect(data.nextCursor, isNull);
      expect(data.loadMoreFailure, isNull);
    });
  });

  group('invalidate', () {
    test('transitions back to loading and refetches first page', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      container.invalidate(expensesProvider);

      expect(container.read(expensesProvider).isLoading, isTrue);

      await container.read(expensesProvider.future);

      verify(() => repository.findAll(cursor: null)).called(2);
    });
  });
}
