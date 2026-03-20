import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/application/use_cases/get_budget_summary_use_case.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IExpenseRepository repository;
  late GetBudgetSummaryUseCase useCase;

  final budget = BudgetModel(
    id: 1,
    amount: 1000.0,
    endDate: DateTime(2026, 3).millisecondsSinceEpoch,
    startDate: DateTime(2026, 2).millisecondsSinceEpoch,
  );

  setUp(() {
    repository = MockExpenseRepository();
    useCase = GetBudgetSummaryUseCase(repository: repository);
  });

  group('GetBudgetSummary', () {
    test('should calculate summary correctly', () {
      when(
        () => repository.findByPeriod(
          endAt: any(named: 'endAt'),
          startAt: any(named: 'startAt'),
        ),
      ).thenReturn(
        Right([
          const ExpenseModel(
            id: 1,
            date: 0,
            amount: 200.0,
            category: 'food',
            description: 'a',
          ),
          const ExpenseModel(
            id: 2,
            date: 0,
            amount: 300.0,
            category: 'food',
            description: 'b',
          ),
        ]),
      );

      final data = useCase(budget);

      expect(data.isRight, true);
      expect(data.right.spent, 500.0);
      expect(data.right.remaining, 500.0);
      expect(data.right.percentage, 0.5);
      expect(data.right.isOverBudget, false);
    });

    test('should detect over budget', () {
      when(
        () => repository.findByPeriod(
          endAt: any(named: 'endAt'),
          startAt: any(named: 'startAt'),
        ),
      ).thenReturn(
        Right([
          const ExpenseModel(
            id: 1,
            date: 0,
            amount: 1200.0,
            category: 'food',
            description: 'a',
          ),
        ]),
      );

      final data = useCase(budget);

      expect(data.isRight, true);
      expect(data.right.remaining, -200.0);
      expect(data.right.isOverBudget, true);
    });

    test('should return Left when repository fails', () {
      when(
        () => repository.findByPeriod(
          endAt: any(named: 'endAt'),
          startAt: any(named: 'startAt'),
        ),
      ).thenReturn(const Left('Ops, a operação falhou.'));

      final data = useCase(budget);

      expect(data.isLeft, true);
      expect(data.left, 'Ops, a operação falhou.');
    });

    test('should return zero spent when no expenses', () {
      when(
        () => repository.findByPeriod(
          endAt: any(named: 'endAt'),
          startAt: any(named: 'startAt'),
        ),
      ).thenReturn(const Right([]));

      final data = useCase(budget);

      expect(data.isRight, true);
      expect(data.right.spent, 0.0);
      expect(data.right.percentage, 0.0);
      expect(data.right.remaining, 1000.0);
    });
  });
}
