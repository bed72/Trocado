import 'dart:math';

import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/budget/active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/home/data/budget_card_presentation_data.dart';

part 'active_budget_notifier.g.dart';

@riverpod
final class ActiveBudgetNotifier extends _$ActiveBudgetNotifier {
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;

  @override
  Future<BudgetCardPresentationData?> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);

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
        (model.remaining / max(1, _daysRemaining(model.endDate))).round();

    return BudgetCardPresentationData(
      percentage: percentage,
      overspent: model.remaining < 0,
      formattedEndDate: _formatEndDate(model.endDate),
      formattedValue: _moneyService.format(model.value / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedTotalSpent: _moneyService.format(model.totalSpent / 100),
      formattedOverspent: _moneyService.format(model.remaining.abs() / 100),
      formattedRemaining: _moneyService.format(max(0, model.remaining) / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
    );
  }

  String _formatEndDate(int endDate) =>
      DateFormat('dd/MM', 'pt_BR').format(.fromMillisecondsSinceEpoch(endDate));

  int _daysRemaining(int endDate) {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(endDate);
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays + 1;
  }
}
