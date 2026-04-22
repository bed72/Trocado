import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

part 'active_budget_notifier.g.dart';

@riverpod
final class ActiveBudgetNotifier extends _$ActiveBudgetNotifier {
  late IBudgetRepository _repository;

  @override
  Future<ActiveBudgetModel?> build() async {
    _repository = ref.watch(budgetRepositoryProvider);

    return await _load();
  }

  Future<ActiveBudgetModel?> _load() async {
    final data = await _repository.findActive();

    return data.fold((failure) => throw failure, (model) => model);
  }
}
