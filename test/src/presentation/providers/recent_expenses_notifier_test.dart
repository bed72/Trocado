import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import '../../../mocks/mocks.dart';

const _expenses = [
  ExpenseModel(
    id: 129,
    value: 8550,
    category: .food,
    date: 1744675200000,
    createdAt: 1745332903000,
    description: 'Cafezinho',
  ),
  ExpenseModel(
    id: 112,
    value: 3891,
    category: .health,
    date: 1745971200000,
    description: 'Farmácia',
    createdAt: 1745331562000,
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

  setUp(() {
    moneyService = MockMoneyService();
    repository = MockExpenseRepository();
    dateFormatter = MockDateFormatterService();

    when(
      () => moneyService.format(any()),
    ).thenAnswer((invocation) => 'R\$ ${invocation.positionalArguments.first}');
    when(() => dateFormatter.formatLongDate(any())).thenReturn('22 de Abr de 2026');
  });

  test(
    'returns AsyncData with mapped ExpenseItemPresentationData when repository returns Right',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Right(_expenses));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      final data = await container.read(recentExpensesProvider.future);

      expect(data, hasLength(2));
      expect(data.last.formattedValue, 'R\$ 38.91');
      expect(data.first.formattedValue, 'R\$ 85.5');
      expect(data.map((item) => item.expense), equals(_expenses));
    },
  );

  test('returns AsyncData with empty list when backend has no data', () async {
    when(
      () => repository.findRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<ExpenseModel>[]));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
      dateFormatter: dateFormatter,
    );
    final data = await container.read(recentExpensesProvider.future);

    expect(data, isEmpty);
  });

  test('calls repository with default limit of 4 on build', () async {
    when(
      () => repository.findRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(_expenses));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
      dateFormatter: dateFormatter,
    );
    await container.read(recentExpensesProvider.future);

    verify(() => repository.findRecent()).called(1);
  });

  test(
    'emits AsyncError when repository returns Left(NetworkFailure)',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(recentExpensesProvider, (_, _) {});
      container.read(recentExpensesProvider);

      await pumpEventQueue();

      expect(container.read(recentExpensesProvider).hasError, isTrue);
      expect(
        container.read(recentExpensesProvider).error,
        isA<NetworkFailure>(),
      );
    },
  );

  test(
    'emits AsyncError when repository returns Left(ServerFailure)',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
        dateFormatter: dateFormatter,
      );
      container.listen(recentExpensesProvider, (_, _) {});
      container.read(recentExpensesProvider);

      await pumpEventQueue();

      expect(container.read(recentExpensesProvider).hasError, isTrue);
      expect(
        container.read(recentExpensesProvider).error,
        isA<ServerFailure>(),
      );
    },
  );
}
