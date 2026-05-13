import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';

part 'active_budget_notifier.g.dart';

@riverpod
final class ActiveBudgetNotifier extends _$ActiveBudgetNotifier {
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<BudgetCardPresentationData?> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    return await _load();
  }

  Future<BudgetCardPresentationData?> _load() async {
    final data = await _repository.findActive();

    return data.fold(
      (failure) => throw failure,
      (model) => model == null ? null : _toCardData(model),
    );
  }

  BudgetCardPresentationData _toCardData(ActiveBudgetModel model) {
    final percentage = model.value > 0 ? model.totalSpent / model.value : 0.0;
    final dailyBudget =
        (model.remaining / max(1, _dateFormatter.daysUntil(model.endDate)))
            .round();

    return BudgetCardPresentationData(
      percentage: percentage,
      overspent: model.remaining < 0,
      formattedValue: _moneyService.format(model.value / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedEndDate: _dateFormatter.formatDayMonth(model.endDate),
      formattedTotalSpent: _moneyService.format(model.totalSpent / 100),
      formattedOverspent: _moneyService.format(model.remaining.abs() / 100),
      formattedRemaining: _moneyService.format(max(0, model.remaining) / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
    );
  }
}
