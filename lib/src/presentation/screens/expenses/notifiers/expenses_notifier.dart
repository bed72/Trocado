import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';
import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_state.dart';

part 'expenses_notifier.g.dart';

@Riverpod(keepAlive: true)
final class ExpensesNotifier extends _$ExpensesNotifier {
  late IMoneyService _moneyService;
  late IExpenseRepository _repository;

  @override
  Future<ExpensesState> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);

    return await _loadFirstPage();
  }

  Future<ExpensesState> _loadFirstPage() async {
    final data = await _repository.findAll();

    return data.fold(
      (failure) => throw failure,
      (page) => ExpensesState(
        nextCursor: page.nextCursor,
        items: page.expenses.map(_toItem).toList(),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    final data = await _repository.findAll(cursor: current.nextCursor);

    state = AsyncData(
      data.fold<ExpensesState>(
        (Failure failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (ExpensesPageModel page) => current.copyWith(
          isLoadingMore: false,
          clearLoadMoreFailure: true,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          items: [...current.items, ...page.expenses.map(_toItem)],
        ),
      ),
    );
  }

  ExpenseItemData _toItem(ExpenseModel expense) => ExpenseItemData(
    expense: expense,
    formattedValue: _moneyService.format(expense.value / 100),
  );
}
