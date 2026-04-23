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
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_notifier.dart';

import 'package:trocado/src/presentation/screens/expenses/data/expense_filter_chip_kind.dart';

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

  setUpAll(() {
    registerFallbackValue(const ExpenseFilterModel.empty());
  });

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
        when(
          () => repository.findAll(
            cursor: any(named: 'cursor'),
            filter: any(named: 'filter'),
          ),
        ).thenAnswer(
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
        expect(data.filter, const ExpenseFilterModel.empty());
        expect(data.isLoadingMore, isFalse);
        expect(data.loadMoreFailure, isNull);
      },
    );

    test('calls findAll with empty filter and no cursor on first build', () async {
      when(
        () => repository.findAll(
          cursor: any(named: 'cursor'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => const Right(ExpensesPageModel()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      verify(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel.empty(),
        ),
      ).called(1);
    });

    test(
      'emits AsyncError when repository returns Left(NetworkFailure)',
      () async {
        when(
          () => repository.findAll(
            cursor: any(named: 'cursor'),
            filter: any(named: 'filter'),
          ),
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
    test('appends items preserving filter on success', () async {
      when(
        () => repository.findAll(
          cursor: null,
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.findAll(
          cursor: 'CUR1',
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
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

    test('is a no-op when nextCursor is null', () async {
      when(
        () => repository.findAll(
          cursor: null,
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _first, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).loadMore();

      verify(
        () => repository.findAll(
          cursor: null,
          filter: any(named: 'filter'),
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('preserves items and records failure on error', () async {
      when(
        () => repository.findAll(
          cursor: null,
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.findAll(
          cursor: 'CUR1',
          filter: any(named: 'filter'),
        ),
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
  });

  group('applyFilter', () {
    test('reloads first page with new filter and exposes chips', () async {
      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategory.food,
      );

      when(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel.empty(),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'INIT'),
        ),
      );
      when(
        () => repository.findAll(cursor: null, filter: filter),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _second, nextCursor: 'F1'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).applyFilter(filter);

      final data = container.read(expensesProvider).value!;
      expect(data.filter, filter);
      expect(data.items.map((item) => item.expense), equals(_second));
      expect(data.nextCursor, 'F1');
      expect(data.activeFilterChips, hasLength(1));
      expect(data.activeFilterChips.first.kind, ExpenseFilterChipKind.category);
    });

    test('emits AsyncError when the reload fails', () async {
      when(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel.empty(),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'INIT'),
        ),
      );
      when(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel(category: ExpenseCategory.food),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).applyFilter(
        const ExpenseFilterModel(category: ExpenseCategory.food),
      );

      expect(container.read(expensesProvider).hasError, isTrue);
      expect(
        container.read(expensesProvider).error,
        isA<NetworkFailure>(),
      );
    });
  });

  group('removeFilter', () {
    test('clears category and reloads', () async {
      final filter = const ExpenseFilterModel.empty().copyWith(
        category: ExpenseCategory.food,
      );

      when(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel.empty(),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'INIT'),
        ),
      );
      when(
        () => repository.findAll(cursor: null, filter: filter),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _second, nextCursor: 'F1'),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).applyFilter(filter);

      await container
          .read(expensesProvider.notifier)
          .removeFilter(ExpenseFilterChipKind.category);

      final data = container.read(expensesProvider).value!;
      expect(data.filter.category, isNull);
      expect(data.activeFilterChips, isEmpty);
    });

    test('clears value bounds when kind is value', () async {
      final filtered = const ExpenseFilterModel.empty().copyWith(
        minValue: 10000,
        maxValue: 50000,
      );

      when(
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
      ).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _first, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).applyFilter(filtered);

      await container
          .read(expensesProvider.notifier)
          .removeFilter(ExpenseFilterChipKind.value);

      final data = container.read(expensesProvider).value!;
      expect(data.filter.minValue, isNull);
      expect(data.filter.maxValue, isNull);
    });

    test('resets ordering to default when kind is ordering', () async {
      final filtered = const ExpenseFilterModel.empty().copyWith(
        ordering: ExpenseOrdering.valueDesc,
      );

      when(
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
      ).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _first, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).applyFilter(filtered);

      await container
          .read(expensesProvider.notifier)
          .removeFilter(ExpenseFilterChipKind.ordering);

      final data = container.read(expensesProvider).value!;
      expect(data.filter.ordering, ExpenseOrdering.dateDesc);
    });
  });
}
