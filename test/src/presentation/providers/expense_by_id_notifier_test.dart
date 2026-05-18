import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_by_id_notifier.dart';

import '../../../mocks/mocks.dart';

const _expense = ExpenseModel(
  id: 132,
  value: 8550,
  category: .food,
  date: 1741996800000,
  description: 'Mercado',
  createdAt: 1741996800000,
);

ProviderContainer _makeContainer({
  required IExpenseRepository repository,
  IMoneyService? moneyService,
  IDateFormatterService? dateFormatter,
}) {
  final formatter = dateFormatter ?? MockDateFormatterService();
  when(() => formatter.formatLongDate(any())).thenReturn('22 de Abr de 2026');
  when(() => formatter.relativeGroupHeader(any())).thenReturn('Hoje');

  final container = ProviderContainer(
    overrides: [
      dateFormatterServiceProvider.overrideWithValue(formatter),
      expenseRepositoryProvider.overrideWithValue(repository),
      if (moneyService != null)
        moneyServiceProvider.overrideWithValue(moneyService),
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

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');
  });

  group('build', () {
    test('returns expense from cache without calling findById', () async {
      when(
        () => repository.findAll(
          cursor: any(named: 'cursor'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => const Right(ExpensesPageModel(expenses: [_expense])),
      );

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      await container.read(expensesProvider.future);

      final data = await container.read(expenseByIdProvider(132).future);

      expect(data, _expense);
      verifyNever(() => repository.findById(id: any(named: 'id')));
    });

    test('falls back to repository.findById when not in cache', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));

      final container = _makeContainer(repository: repository);

      final data = await container.read(expenseByIdProvider(132).future);

      expect(data, _expense);
      verify(() => repository.findById(id: 132)).called(1);
    });

    test('emits AsyncError when repository returns Left', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final container = _makeContainer(repository: repository);
      container.listen(expenseByIdProvider(132), (_, _) {});
      container.read(expenseByIdProvider(132));

      await pumpEventQueue();

      expect(container.read(expenseByIdProvider(132)).hasError, isTrue);
      expect(
        container.read(expenseByIdProvider(132)).error,
        isA<NotFoundFailure>(),
      );
    });
  });
}
