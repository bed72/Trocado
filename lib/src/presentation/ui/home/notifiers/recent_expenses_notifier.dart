import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';

part 'recent_expenses_notifier.g.dart';

@Riverpod()
final class RecentExpensesNotifier extends _$RecentExpensesNotifier {
  late IMoneyService _moneyService;
  late IExpenseRepository _repository;
  late IDateFormatterService _dateService;

  @override
  Future<List<ExpenseItemPresentationData>> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);
    _dateService = ref.watch(dateFormatterServiceProvider);

    return await _load();
  }

  Future<List<ExpenseItemPresentationData>> _load() async {
    final data = await _repository.findRecent();

    return data.fold(
      (failure) => throw failure,
      (expenses) => expenses.map(_toItem).toList(),
    );
  }

  ExpenseItemPresentationData _toItem(ExpenseModel expense) =>
      ExpenseItemPresentationData(
        expense: expense,
        formattedValue: _moneyService.format(expense.value / 100),
        formattedTime: _dateService.formatTime(expense.createdAt),
        formattedDate: _dateService.formatDayMonth(expense.createdAt),
      );
}
