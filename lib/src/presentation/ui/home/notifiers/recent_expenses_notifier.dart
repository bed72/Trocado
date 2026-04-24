import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/data/expense_item_data.dart';

part 'recent_expenses_notifier.g.dart';

@riverpod
final class RecentExpensesNotifier extends _$RecentExpensesNotifier {
  late IMoneyService _moneyService;
  late IExpenseRepository _repository;

  @override
  Future<List<ExpenseItemData>> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);

    return await _load();
  }

  Future<List<ExpenseItemData>> _load() async {
    final data = await _repository.findRecent();

    return data.fold(
      (failure) => throw failure,
      (expenses) => expenses.map(_toItem).toList(),
    );
  }

  ExpenseItemData _toItem(ExpenseModel expense) => ExpenseItemData(
    expense: expense,
    formattedValue: _moneyService.format(expense.value / 100),
  );
}
