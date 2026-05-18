import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';

import '../../../mocks/mocks.dart';

final _now = DateTime.now();
final _nowMs = _now.millisecondsSinceEpoch;
final _crossYearEnd = DateTime(2025, 1, 14).millisecondsSinceEpoch;
final _crossYearStart = DateTime(2024, 12, 15).millisecondsSinceEpoch;
final _activeEnd = _now.add(const Duration(days: 25)).millisecondsSinceEpoch;
final _pastEnd = _now.subtract(const Duration(days: 60)).millisecondsSinceEpoch;
final _pastStart = _now
    .subtract(const Duration(days: 90))
    .millisecondsSinceEpoch;
final _olderEnd = _now
    .subtract(const Duration(days: 150))
    .millisecondsSinceEpoch;
final _activeStart = _now
    .subtract(const Duration(days: 5))
    .millisecondsSinceEpoch;
final _olderStart = _now
    .subtract(const Duration(days: 180))
    .millisecondsSinceEpoch;

BudgetModel _activeBudget() => BudgetModel(
  id: 1,
  value: 100000,
  remaining: 75000,
  totalSpent: 25000,
  createdAt: _nowMs,
  endDate: _activeEnd,
  description: 'Active',
  startDate: _activeStart,
);

BudgetModel _pastBudget() => BudgetModel(
  id: 2,
  value: 80000,
  remaining: 20000,
  totalSpent: 60000,
  endDate: _pastEnd,
  description: 'Past',
  startDate: _pastStart,
  createdAt: _pastStart,
);

BudgetModel _olderBudget() => BudgetModel(
  id: 3,
  value: 50000,
  remaining: 0,
  totalSpent: 50000,
  endDate: _olderEnd,
  description: 'Older',
  startDate: _olderStart,
  createdAt: _olderStart,
);

BudgetModel _crossYearBudget() => BudgetModel(
  id: 4,
  value: 30000,
  remaining: 20000,
  totalSpent: 10000,
  endDate: _crossYearEnd,
  description: 'Cross year',
  startDate: _crossYearStart,
  createdAt: _crossYearStart,
);

ProviderContainer _makeContainer({
  required IMoneyService moneyService,
  required IBudgetRepository repository,
  required IDateFormatterService dateFormatter,
}) {
  final container = ProviderContainer(
    overrides: [
      nowProvider.overrideWithValue(() => _now),
      moneyServiceProvider.overrideWithValue(moneyService),
      budgetRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IBudgetRepository repository;
  late IDateFormatterService dateFormatter;

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockBudgetRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');

    when(() => dateFormatter.formatPeriod(any(), any())).thenAnswer(
      (invocation) =>
          'PERIOD(${invocation.positionalArguments[0]}-${invocation.positionalArguments[1]})',
    );
    when(() => dateFormatter.formatLongDate(any())).thenReturn('30 de Abr');
    when(() => dateFormatter.daysUntil(any())).thenReturn(10);
  });

  group('build', () {
    test(
      'selects activeCard when a budget covers today and excludes it from items',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(
              budgets: [_activeBudget(), _pastBudget(), _olderBudget()],
              nextCursor: 'CUR1',
            ),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        final state = await container.read(budgetsProvider.future);

        expect(state.nextCursor, 'CUR1');
        expect(state.items, hasLength(2));
        expect(state.activeCard, isNotNull);
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreFailure, isNull);
        expect(state.items.map((item) => item.budget.id).toList(), [2, 3]);
      },
    );

    test('sets activeCard to null when no budget covers today', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(
            budgets: [_pastBudget(), _olderBudget()],
            nextCursor: null,
          ),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      final state = await container.read(budgetsProvider.future);

      expect(state.activeCard, isNull);
      expect(state.items, hasLength(2));
    });

    test('exposes AsyncError when repository returns Left', () async {
      when(
        () => repository.findAll(cursor: any(named: 'cursor')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(budgetsProvider, (_, _) {});
      container.read(budgetsProvider);

      await pumpEventQueue();

      expect(container.read(budgetsProvider).hasError, isTrue);
      expect(container.read(budgetsProvider).error, isA<NetworkFailure>());
    });

    test('calls findAll with no cursor on first build', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async =>
            const Right(BudgetsPageModel(budgets: [], nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);

      verify(() => repository.findAll(cursor: null)).called(1);
    });

    test(
      'item view-model exposes formatted money strings via IMoneyService',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(budgets: [_pastBudget()], nextCursor: null),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        final state = await container.read(budgetsProvider.future);
        final item = state.items.single;

        expect(item.formattedValue, 'R\$ 800.0');
        expect(item.formattedRemaining, 'R\$ 200.0');
        expect(item.formattedTotalSpent, 'R\$ 600.0');
      },
    );

    test(
      'item view-model delegates formattedPeriod to IDateFormatterService',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(budgets: [_crossYearBudget()], nextCursor: null),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        final state = await container.read(budgetsProvider.future);

        expect(
          state.items.single.formattedPeriod,
          'PERIOD($_crossYearStart-$_crossYearEnd)',
        );
        verify(
          () => dateFormatter.formatPeriod(_crossYearStart, _crossYearEnd),
        ).called(1);
      },
    );
  });

  group('loadMore', () {
    test(
      'appends items preserving existing items, activeCard and updates nextCursor',
      () async {
        when(() => repository.findAll(cursor: null)).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(
              nextCursor: 'CUR1',
              budgets: [_activeBudget(), _pastBudget()],
            ),
          ),
        );
        when(() => repository.findAll(cursor: 'CUR1')).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(budgets: [_olderBudget()], nextCursor: 'CUR2'),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        await container.read(budgetsProvider.future);
        await container.read(budgetsProvider.notifier).loadMore();

        final state = container.read(budgetsProvider).value!;

        expect(state.nextCursor, 'CUR2');
        expect(state.activeCard, isNotNull);
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreFailure, isNull);
        expect(state.items.map((item) => item.budget.id).toList(), [2, 3]);
      },
    );

    test('clears nextCursor when next page returns nextCursor null', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(budgets: [_pastBudget()], nextCursor: 'CUR1'),
        ),
      );
      when(() => repository.findAll(cursor: 'CUR1')).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(budgets: [_olderBudget()], nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).loadMore();

      expect(container.read(budgetsProvider).value!.nextCursor, isNull);
    });

    test('is a no-op when nextCursor is null', () async {
      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async =>
            Right(BudgetsPageModel(budgets: [_pastBudget()], nextCursor: null)),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).loadMore();

      verify(() => repository.findAll(cursor: null)).called(1);
      verifyNever(
        () => repository.findAll(
          cursor: any(named: 'cursor', that: isNotNull),
        ),
      );
    });

    test('is a no-op when isLoadingMore is true', () async {
      final completer = Completer<Either<Failure, BudgetsPageModel>>();

      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(budgets: [_pastBudget()], nextCursor: 'CUR1'),
        ),
      );
      when(
        () => repository.findAll(cursor: 'CUR1'),
      ).thenAnswer((_) => completer.future);

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(budgetsProvider, (_, _) {});
      await container.read(budgetsProvider.future);

      final notifier = container.read(budgetsProvider.notifier);
      final firstCall = notifier.loadMore();
      await pumpEventQueue();
      await notifier.loadMore();

      verify(() => repository.findAll(cursor: 'CUR1')).called(1);

      completer.complete(
        Right(BudgetsPageModel(budgets: [_olderBudget()], nextCursor: null)),
      );
      await firstCall;
    });

    test(
      'on failure preserves items and activeCard, sets loadMoreFailure',
      () async {
        when(() => repository.findAll(cursor: null)).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(
              budgets: [_activeBudget(), _pastBudget()],
              nextCursor: 'CUR1',
            ),
          ),
        );
        when(
          () => repository.findAll(cursor: 'CUR1'),
        ).thenAnswer((_) async => const Left(ServerFailure()));

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
          dateFormatter: dateFormatter,
        );
        await container.read(budgetsProvider.future);
        await container.read(budgetsProvider.notifier).loadMore();

        final state = container.read(budgetsProvider).value!;

        expect(state.nextCursor, 'CUR1');
        expect(state.activeCard, isNotNull);
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreFailure, isA<ServerFailure>());
        expect(state.items.map((item) => item.budget.id).toList(), [2]);
      },
    );

    test('retry after failure clears loadMoreFailure on success', () async {
      int callCount = 0;

      when(() => repository.findAll(cursor: null)).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(budgets: [_pastBudget()], nextCursor: 'CUR1'),
        ),
      );
      when(() => repository.findAll(cursor: 'CUR1')).thenAnswer((_) async {
        callCount += 1;
        if (callCount == 1) return const Left(ServerFailure());
        return Right(
          BudgetsPageModel(budgets: [_olderBudget()], nextCursor: null),
        );
      });

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).loadMore();

      expect(
        container.read(budgetsProvider).value!.loadMoreFailure,
        isA<ServerFailure>(),
      );

      await container.read(budgetsProvider.notifier).loadMore();

      final state = container.read(budgetsProvider).value!;
      expect(state.nextCursor, isNull);
      expect(state.loadMoreFailure, isNull);
      expect(state.items.map((item) => item.budget.id).toList(), [2, 3]);
    });
  });

  group('refresh via invalidate', () {
    test('re-runs build and refetches first page', () async {
      int page = 0;

      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer((
        _,
      ) async {
        page += 1;
        return Right(
          BudgetsPageModel(
            budgets: page == 1 ? [_pastBudget()] : [_olderBudget()],
            nextCursor: null,
          ),
        );
      });

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);
      container.invalidate(budgetsProvider);
      final reloaded = await container.read(budgetsProvider.future);

      expect(reloaded.items.single.budget.id, 3);
      verify(() => repository.findAll(cursor: null)).called(2);
    });
  });

  group('deleteById', () {
    test('removes item optimistically and calls repository.delete', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(
            budgets: [_activeBudget(), _pastBudget(), _olderBudget()],
            nextCursor: null,
          ),
        ),
      );
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );

      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).deleteById(2);

      final data = container.read(budgetsProvider).value!;
      expect(data.items.map((item) => item.budget.id), [3]);
      expect(data.deleteFailure, isNull);
      verify(() => repository.delete(id: 2)).called(1);
    });

    test('restores item and sets deleteFailure on failure', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(
            budgets: [_activeBudget(), _pastBudget(), _olderBudget()],
            nextCursor: null,
          ),
        ),
      );
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );

      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).deleteById(2);

      final data = container.read(budgetsProvider).value!;
      expect(data.items.map((item) => item.budget.id), [2, 3]);
      expect(data.deleteFailure, isA<NetworkFailure>());
    });

    test('is a no-op when id is not in state', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(
            budgets: [_activeBudget(), _pastBudget()],
            nextCursor: null,
          ),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );

      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).deleteById(999);

      verifyNever(() => repository.delete(id: any(named: 'id')));
    });
  });
}
