import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

part 'recent_expenses_notifier.g.dart';

@riverpod
final class RecentExpensesNotifier extends _$RecentExpensesNotifier {
  late IExpenseRepository _repository;

  @override
  Future<List<ExpenseModel>> build() async {
    _repository = ref.watch(expenseRepositoryProvider);

    return await _load();
  }

  Future<List<ExpenseModel>> _load() async {
    final data = await _repository.findRecent();

    return data.fold((failure) => throw failure, (expenses) => expenses);
  }
}
