import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/screens/home/notifiers/recent_expenses_notifier.dart';

import '../../../mocks/mocks.dart';

const _expenses = [
  ExpenseModel(
    id: 129,
    value: 8550,
    date: 1744675200000,
    createdAt: 1745332903000,
    description: 'Cafezinho',
    category: ExpenseCategoryEnum.food,
  ),
  ExpenseModel(
    id: 112,
    value: 3891,
    date: 1745971200000,
    createdAt: 1745331562000,
    description: 'Farmácia',
    category: ExpenseCategoryEnum.health,
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

  test(
    'returns AsyncData with mapped ExpenseItemData when repository returns Right',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Right(_expenses));

      final container = _makeContainer(
        repository: repository,
        moneyService: moneyService,
      );
      final data = await container.read(recentExpensesProvider.future);

      expect(data, hasLength(2));
      expect(data.map((item) => item.expense), equals(_expenses));
      expect(data.first.formattedValue, 'R\$ 85.5');
      expect(data.last.formattedValue, 'R\$ 38.91');
    },
  );

  test('returns AsyncData with empty list when backend has no data', () async {
    when(
      () => repository.findRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<ExpenseModel>[]));

    final container = _makeContainer(
      repository: repository,
      moneyService: moneyService,
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
