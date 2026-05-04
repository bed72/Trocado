import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';

part 'budget_by_id_notifier.g.dart';

@riverpod
final class BudgetByIdNotifier extends _$BudgetByIdNotifier {
  late IBudgetRepository _repository;

  @override
  Future<BudgetModel> build(int id) async {
    _repository = ref.watch(budgetRepositoryProvider);

    final cached = _readFromCache(id);
    if (cached != null) return cached;

    return await _findById(id);
  }

  Future<BudgetModel> _findById(int id) async {
    final data = await _repository.findById(id: id);

    return data.fold((failure) => throw failure, (model) => model);
  }

  BudgetModel? _readFromCache(int id) {
    final budgetsState = ref.read(budgetsProvider);

    if (budgetsState case AsyncData(:final value)) {
      for (final item in value.items) {
        if (item.budget.id == id) return item.budget;
      }
      if (value.activeBudget?.id == id) return value.activeBudget;
    }

    return null;
  }
}
