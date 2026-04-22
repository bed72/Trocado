import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/core/either/either.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expense_category.dart';
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
    category: ExpenseCategory.food,
  ),
  ExpenseModel(
    id: 112,
    value: 3891,
    date: 1745971200000,
    createdAt: 1745331562000,
    description: 'Farmácia',
    category: ExpenseCategory.health,
  ),
];

ProviderContainer _makeContainer(IExpenseRepository repository) {
  final container = ProviderContainer(
    overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late IExpenseRepository repository;

  setUp(() {
    repository = MockExpenseRepository();
  });

  test(
    'returns AsyncData with expenses when repository returns Right',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Right(_expenses));

      final container = _makeContainer(repository);
      final data = await container.read(recentExpensesProvider.future);

      expect(data, equals(_expenses));
    },
  );

  test('returns AsyncData with empty list when backend has no data', () async {
    when(
      () => repository.findRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<ExpenseModel>[]));

    final container = _makeContainer(repository);
    final data = await container.read(recentExpensesProvider.future);

    expect(data, isEmpty);
  });

  test('calls repository with default limit of 4 on build', () async {
    when(
      () => repository.findRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(_expenses));

    final container = _makeContainer(repository);
    await container.read(recentExpensesProvider.future);

    verify(() => repository.findRecent()).called(1);
  });

  test(
    'emits AsyncError when repository returns Left(NetworkFailure)',
    () async {
      when(
        () => repository.findRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(repository);
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

      final container = _makeContainer(repository);
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
