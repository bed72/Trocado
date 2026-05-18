import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/budget_by_id_notifier.dart';

import '../../../mocks/mocks.dart';

final _now = DateTime.now();
final _activeStart = _now
    .subtract(const Duration(days: 5))
    .millisecondsSinceEpoch;
final _activeEnd = _now.add(const Duration(days: 25)).millisecondsSinceEpoch;
final _pastStart = _now
    .subtract(const Duration(days: 90))
    .millisecondsSinceEpoch;
final _pastEnd = _now.subtract(const Duration(days: 60)).millisecondsSinceEpoch;

BudgetModel _activeBudget() => BudgetModel(
  id: 7,
  value: 100000,
  remaining: 75000,
  totalSpent: 25000,
  endDate: _activeEnd,
  description: 'Active',
  startDate: _activeStart,
);

BudgetModel _pastBudget() => BudgetModel(
  id: 9,
  value: 80000,
  remaining: 20000,
  totalSpent: 60000,
  endDate: _pastEnd,
  description: 'Past',
  startDate: _pastStart,
);

ProviderContainer _makeContainer({
  required IBudgetRepository repository,
  required IDateFormatterService dateFormatter,
  IMoneyService? moneyService,
}) {
  final container = ProviderContainer(
    overrides: [
      nowProvider.overrideWithValue(() => _now),
      budgetRepositoryProvider.overrideWithValue(repository),
      dateFormatterServiceProvider.overrideWithValue(dateFormatter),
      if (moneyService != null)
        moneyServiceProvider.overrideWithValue(moneyService),
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

    when(
      () => dateFormatter.formatPeriod(any(), any()),
    ).thenReturn('01/05 – 30/05');
    when(() => dateFormatter.formatLongDate(any())).thenReturn('30 de Mai');
    when(() => dateFormatter.daysUntil(any())).thenReturn(10);
  });

  group('build', () {
    test('returns active budget from cache without calling findById', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(budgets: [_activeBudget()], nextCursor: null),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);

      final data = await container.read(budgetByIdProvider(7).future);

      expect(data, _activeBudget());
      verifyNever(() => repository.findById(id: any(named: 'id')));
    });

    test('returns budget from items cache without calling findById', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          BudgetsPageModel(
            nextCursor: null,
            budgets: [_activeBudget(), _pastBudget()],
          ),
        ),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);

      final data = await container.read(budgetByIdProvider(9).future);

      expect(data, _pastBudget());
      verifyNever(() => repository.findById(id: any(named: 'id')));
    });

    test('falls back to repository.findById when not in cache', () async {
      when(() => repository.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(BudgetsPageModel(budgets: [], nextCursor: null)),
      );
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => Right(_activeBudget()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      await container.read(budgetsProvider.future);

      final data = await container.read(budgetByIdProvider(7).future);

      expect(data, _activeBudget());
      verify(() => repository.findById(id: 7)).called(1);
    });

    test('emits AsyncError when repository returns Left', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = _makeContainer(
        repository: repository,
        dateFormatter: dateFormatter,
      );
      container.listen(budgetByIdProvider(7), (_, _) {});
      container.read(budgetByIdProvider(7));

      await pumpEventQueue();

      expect(container.read(budgetByIdProvider(7)).hasError, isTrue);
      expect(
        container.read(budgetByIdProvider(7)).error,
        isA<NotFoundFailure>(),
      );
    });
  });
}
