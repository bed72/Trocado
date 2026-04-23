import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/screens/home/data/budget_card_data.dart';

part 'active_budget_notifier.g.dart';

@riverpod
final class ActiveBudgetNotifier extends _$ActiveBudgetNotifier {
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;

  @override
  Future<BudgetCardData?> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);

    return await _load();
  }

  Future<BudgetCardData?> _load() async {
    final data = await _repository.findActive();

    return data.fold(
      (failure) => throw failure,
      (model) => model == null ? null : _toCardData(model),
    );
  }

  BudgetCardData _toCardData(ActiveBudgetModel model) {
    final percentage = model.value > 0 ? model.totalSpent / model.value : 0.0;
    final dailyBudget =
        (model.remaining / max(1, _daysRemaining(model.endDate))).round();

    return BudgetCardData(
      percentage: percentage,
      overspent: model.remaining < 0,
      formattedValue: _moneyService.format(model.value / 100),
      formattedRemaining: _moneyService.format(max(0, model.remaining) / 100),
      formattedOverspent: _moneyService.format(model.remaining.abs() / 100),
      formattedTotalSpent: _moneyService.format(model.totalSpent / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
    );
  }

  int _daysRemaining(int endDate) =>
      DateTime.fromMillisecondsSinceEpoch(endDate)
          .difference(DateTime.now())
          .inDays +
      1;
}
