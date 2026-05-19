import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';


import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';

import '../../../mocks/mocks.dart';

const _first = [
  ExpenseModel(
    id: 1,
    value: 8550,
    category: .food,
    date: 1744675200000,
    createdAt: 1745332903000,
    description: 'Cafezinho',
  ),
  ExpenseModel(
    id: 2,
    value: 3891,
    category: .health,
    date: 1745971200000,
    description: 'Farmácia',
    createdAt: 1745331562000,
  ),
];

const _second = [
  ExpenseModel(
    id: 3,
    value: 2000,
    date: 1744500000000,
    description: 'Uber',
    category: .transport,
    createdAt: 1745330000000,
  ),
];

ProviderContainer _makeContainer({
  required IMoneyService moneyService,
  required IExpenseRepository repository,
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    overrides: [
      moneyServiceProvider.overrideWithValue(moneyService),
      expenseRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IExpenseRepository repository;
  late IDateFormatterService dateFormatter;

  setUpAll(() {
    registerFallbackValue(const ExpenseFilterModel.empty());
  });

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockExpenseRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');
    when(
      () => dateFormatter.formatLongDate(any()),
    ).thenReturn('22 de Abr de 2026');
    when(() => dateFormatter.relativeGroupHeader(any())).thenReturn('Hoje');
    when(() => dateFormatter.formatPeriod(any(), any())).thenAnswer(
      (invocation) =>
          'PERIOD(${invocation.positionalArguments[0]},${invocation.positionalArguments[1]})',
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
          dateFormatter: dateFormatter,
        );
        final data = await container.read(expensesProvider.future);

        expect(data.nextCursor, 'CUR1');
        expect(data.items, hasLength(2));
        expect(data.isLoadingMore, isFalse);
        expect(data.loadMoreFailure, isNull);
        expect(data.items.first.formattedValue, 'R\$ 85.5');
        expect(data.filter, const ExpenseFilterModel.empty());
        expect(data.items.map((item) => item.expense), equals(_first));
      },
    );

    test(
      'calls findAll with empty filter and no cursor on first build',
      () async {
        when(
          () => repository.findAll(
            cursor: any(named: 'cursor'),
            filter: any(named: 'filter'),
          ),
        ).thenAnswer((_) async => const Right(ExpensesPageModel()));

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        await container.read(expensesProvider.future);

        verify(
          () => repository.findAll(cursor: null, filter: const .empty()),
        ).called(1);
      },
    );

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
          dateFormatter: dateFormatter,
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
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
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
        dateFormatter: dateFormatter,
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
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
      ).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _first, nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).loadMore();

      verify(
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('preserves items and records failure on error', () async {
      when(
        () => repository.findAll(cursor: null, filter: any(named: 'filter')),
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
        dateFormatter: dateFormatter,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).loadMore();

      final data = container.read(expensesProvider).value!;

      expect(data.nextCursor, 'CUR1');
      expect(data.isLoadingMore, isFalse);
      expect(data.loadMoreFailure, isA<ServerFailure>());
      expect(data.items.map((item) => item.expense), equals(_first));
    });
  });

  group('applyFilter', () {
    test('reloads first page with new filter and exposes chips', () async {
      final filter = const ExpenseFilterModel.empty().copyWith(category: .food);

      when(
        () => repository.findAll(cursor: null, filter: const .empty()),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'INIT'),
        ),
      );
      when(() => repository.findAll(cursor: null, filter: filter)).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _second, nextCursor: 'F1')),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(expensesProvider.future);

      await container.read(expensesProvider.notifier).applyFilter(filter);

      final data = container.read(expensesProvider).value!;

      expect(data.filter, filter);
      expect(data.nextCursor, 'F1');
      expect(data.activeFilterChips, hasLength(1));
      expect(data.items.map((item) => item.expense), equals(_second));
      expect(data.activeFilterChips.first.kind, ExpenseFilterChipKind.category);
    });

    test('emits AsyncError when the reload fails', () async {
      when(
        () => repository.findAll(cursor: null, filter: const .empty()),
      ).thenAnswer(
        (_) async => const Right(
          ExpensesPageModel(expenses: _first, nextCursor: 'INIT'),
        ),
      );
      when(
        () => repository.findAll(
          cursor: null,
          filter: const ExpenseFilterModel(category: .food),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(expensesProvider.future);

      await container
          .read(expensesProvider.notifier)
          .applyFilter(const ExpenseFilterModel(category: .food));

      expect(container.read(expensesProvider).hasError, isTrue);
      expect(container.read(expensesProvider).error, isA<NetworkFailure>());
    });
  });

  group('removeFilter', () {
    test('clears category and reloads', () async {
      final filter = const ExpenseFilterModel.empty().copyWith(category: .food);

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
      when(() => repository.findAll(cursor: null, filter: filter)).thenAnswer(
        (_) async =>
            const Right(ExpensesPageModel(expenses: _second, nextCursor: 'F1')),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).applyFilter(filter);

      await container.read(expensesProvider.notifier).removeFilter(.category);

      final data = container.read(expensesProvider).value!;
      expect(data.filter.category, isNull);
      expect(data.activeFilterChips, isEmpty);
    });

  });

  group('deleteById', () {
    test('removes item optimistically and calls repository.delete', () async {
      when(
        () => repository.findAll(
          filter: any(named: 'filter'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => const Right(ExpensesPageModel(expenses: _first)),
      );
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        moneyService: moneyService,
        repository: repository,
        dateFormatter: dateFormatter,
      );

      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).deleteById(1);

      final data = container.read(expensesProvider).value!;

      expect(data.deleteFailure, isNull);
      expect(data.items.map((item) => item.expense.id), [2]);

      verify(() => repository.delete(id: 1)).called(1);
    });

    test('restores item and sets deleteFailure on failure', () async {
      when(
        () => repository.findAll(
          filter: any(named: 'filter'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => const Right(ExpensesPageModel(expenses: _first)),
      );
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        moneyService: moneyService,
        repository: repository,
        dateFormatter: dateFormatter,
      );

      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).deleteById(1);

      final data = container.read(expensesProvider).value!;

      expect(data.deleteFailure, isA<NetworkFailure>());
      expect(data.items.map((item) => item.expense.id), [1, 2]);
    });

    test('is a no-op when id is not in state', () async {
      when(
        () => repository.findAll(
          filter: any(named: 'filter'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => const Right(ExpensesPageModel(expenses: _first)),
      );

      final container = _makeContainer(
        moneyService: moneyService,
        repository: repository,
        dateFormatter: dateFormatter,
      );

      await container.read(expensesProvider.future);
      await container.read(expensesProvider.notifier).deleteById(999);

      verifyNever(() => repository.delete(id: any(named: 'id')));
    });
  });
}
