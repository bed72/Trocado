import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/usecases/get_budget_summary.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockExpenseRepository expenseRepository;
  late GetBudgetSummary useCase;

  final budget = BudgetModel(
    id: 1,
    amount: 1000.0,
    startDate: DateTime(2026, 2).millisecondsSinceEpoch,
    endDate: DateTime(2026, 3).millisecondsSinceEpoch,
  );

  setUp(() {
    expenseRepository = MockExpenseRepository();
    useCase = GetBudgetSummary(expenseRepository: expenseRepository);
  });

  group('GetBudgetSummary', () {
    test('should calculate summary correctly', () {
      when(
        () => expenseRepository.findByPeriod(
          startAt: any(named: 'startAt'),
          endAt: any(named: 'endAt'),
        ),
      ).thenReturn(Right([
        const ExpenseModel(
          id: 1, amount: 200.0, date: 0, category: 'food', description: 'a',
        ),
        const ExpenseModel(
          id: 2, amount: 300.0, date: 0, category: 'food', description: 'b',
        ),
      ]));

      final result = useCase(budget);

      expect(result.isRight, true);
      expect(result.right.spent, 500.0);
      expect(result.right.remaining, 500.0);
      expect(result.right.percentage, 0.5);
      expect(result.right.isOverBudget, false);
    });

    test('should detect over budget', () {
      when(
        () => expenseRepository.findByPeriod(
          startAt: any(named: 'startAt'),
          endAt: any(named: 'endAt'),
        ),
      ).thenReturn(Right([
        const ExpenseModel(
          id: 1, amount: 1200.0, date: 0, category: 'food', description: 'a',
        ),
      ]));

      final result = useCase(budget);

      expect(result.isRight, true);
      expect(result.right.isOverBudget, true);
      expect(result.right.remaining, -200.0);
    });

    test('should return Left when repository fails', () {
      when(
        () => expenseRepository.findByPeriod(
          startAt: any(named: 'startAt'),
          endAt: any(named: 'endAt'),
        ),
      ).thenReturn(const Left('Ops, a operação falhou.'));

      final result = useCase(budget);

      expect(result.isLeft, true);
      expect(result.left, 'Ops, a operação falhou.');
    });

    test('should return zero spent when no expenses', () {
      when(
        () => expenseRepository.findByPeriod(
          startAt: any(named: 'startAt'),
          endAt: any(named: 'endAt'),
        ),
      ).thenReturn(const Right([]));

      final result = useCase(budget);

      expect(result.isRight, true);
      expect(result.right.spent, 0.0);
      expect(result.right.remaining, 1000.0);
      expect(result.right.percentage, 0.0);
    });
  });
}
