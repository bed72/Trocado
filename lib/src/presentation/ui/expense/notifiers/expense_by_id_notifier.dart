import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';

part 'expense_by_id_notifier.g.dart';

@riverpod
final class ExpenseByIdNotifier extends _$ExpenseByIdNotifier {
  late IExpenseRepository _repository;

  @override
  Future<ExpenseModel> build(int id) async {
    _repository = ref.watch(expenseRepositoryProvider);

    final cached = _readFromCache(id);
    if (cached != null) return cached;

    return await _findById(id);
  }

  Future<ExpenseModel> _findById(int id) async {
    final data = await _repository.findById(id: id);

    return data.fold((failure) => throw failure, (model) => model);
  }

  ExpenseModel? _readFromCache(int id) {
    final expensesState = ref.read(expensesProvider);

    if (expensesState case AsyncData(:final value)) {
      for (final item in value.items) {
        if (item.expense.id == id) return item.expense;
      }
    }

    return null;
  }
}
