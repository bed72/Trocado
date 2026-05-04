import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
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
}) {
  final container = ProviderContainer(
    overrides: [
      moneyServiceProvider.overrideWithValue(moneyService),
      budgetRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IMoneyService moneyService;
  late IBudgetRepository repository;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockBudgetRepository();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');
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
        );
        final state = await container.read(budgetsProvider.future);
        final item = state.items.single;

        expect(item.formattedValue, 'R\$ 800.0');
        expect(item.formattedTotalSpent, 'R\$ 600.0');
        expect(item.formattedRemaining, 'R\$ 200.0');
      },
    );

    test(
      'item view-model exposes formattedPeriod for same-year budgets',
      () async {
        final pickedMonth = _now.month == 1 ? 6 : 1;
        final start = DateTime(
          _now.year,
          pickedMonth,
          1,
        ).millisecondsSinceEpoch;
        final end = DateTime(_now.year, pickedMonth, 28).millisecondsSinceEpoch;
        final budget = BudgetModel(
          id: 10,
          endDate: end,
          value: 100000,
          totalSpent: 0,
          startDate: start,
          remaining: 100000,
          createdAt: _nowMs,
          description: 'Same year',
        );
        final monthLabel = pickedMonth.toString().padLeft(2, '0');

        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async =>
              Right(BudgetsPageModel(budgets: [budget], nextCursor: null)),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
        );
        final state = await container.read(budgetsProvider.future);

        expect(
          state.items.single.formattedPeriod,
          '01/$monthLabel – 28/$monthLabel',
        );
      },
    );

    test(
      'item view-model exposes formattedPeriod for cross-year budgets',
      () async {
        when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => Right(
            BudgetsPageModel(budgets: [_crossYearBudget()], nextCursor: null),
          ),
        );

        final container = _makeContainer(
          repository: repository,
          moneyService: moneyService,
        );
        final state = await container.read(budgetsProvider.future);

        expect(state.items.single.formattedPeriod, '15/12/24 – 14/01/25');
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
              budgets: [_activeBudget(), _pastBudget()],
              nextCursor: 'CUR1',
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
        );
        await container.read(budgetsProvider.future);
        await container.read(budgetsProvider.notifier).loadMore();

        final state = container.read(budgetsProvider).value!;
        expect(state.items.map((item) => item.budget.id).toList(), [2, 3]);
        expect(state.nextCursor, 'CUR2');
        expect(state.activeCard, isNotNull);
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreFailure, isNull);
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
        );
        await container.read(budgetsProvider.future);
        await container.read(budgetsProvider.notifier).loadMore();

        final state = container.read(budgetsProvider).value!;
        expect(state.items.map((item) => item.budget.id).toList(), [2]);
        expect(state.activeCard, isNotNull);
        expect(state.nextCursor, 'CUR1');
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreFailure, isA<ServerFailure>());
      },
    );

    test('retry after failure clears loadMoreFailure on success', () async {
      var callCount = 0;

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
      );
      await container.read(budgetsProvider.future);
      await container.read(budgetsProvider.notifier).loadMore();

      expect(
        container.read(budgetsProvider).value!.loadMoreFailure,
        isA<ServerFailure>(),
      );

      await container.read(budgetsProvider.notifier).loadMore();

      final state = container.read(budgetsProvider).value!;
      expect(state.loadMoreFailure, isNull);
      expect(state.items.map((item) => item.budget.id).toList(), [2, 3]);
      expect(state.nextCursor, isNull);
    });
  });

  group('refresh via invalidate', () {
    test('re-runs build and refetches first page', () async {
      var page = 0;

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
      );
      await container.read(budgetsProvider.future);
      container.invalidate(budgetsProvider);
      final reloaded = await container.read(budgetsProvider.future);

      expect(reloaded.items.single.budget.id, 3);
      verify(() => repository.findAll(cursor: null)).called(2);
    });
  });
}
