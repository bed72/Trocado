import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/budget/budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/partner_budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/shared_active_budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/data/budget/shared_budget_card_presentation_data.dart';

part 'shared_active_budget_notifier.g.dart';

@Riverpod()
final class SharedActiveBudgetNotifier
    extends _$SharedActiveBudgetNotifier {
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<SharedBudgetCardPresentationData?> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    return await _load();
  }

  Future<SharedBudgetCardPresentationData?> _load() async {
    final data = await _repository.findActiveShared();

    return data.fold(
      (failure) => throw failure,
      (model) => model == null ? null : _toCardData(model),
    );
  }

  SharedBudgetCardPresentationData _toCardData(SharedActiveBudgetModel model) {
    final combined = model.combined;
    final percentage = combined.value > 0
        ? combined.totalSpent / combined.value
        : 0.0;
    final dailyBudget =
        (combined.remaining / max(1, _dateFormatter.daysUntil(model.period.endDate)))
            .round();

    return SharedBudgetCardPresentationData(
      percentage: percentage,
      mySlice: _toMySlice(model.me),
      overspent: combined.remaining < 0,
      partnerSlice: _toPartnerSlice(model.partner),
      partnerHasDifferentPeriod: model.partnerHasDifferentPeriod,
      formattedTotal: _moneyService.format(combined.value / 100),
      formattedSpent: _moneyService.format(combined.totalSpent / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedEndDate: _dateFormatter.formatLongDate(model.period.endDate),
      formattedOverspent: _moneyService.format(combined.remaining.abs() / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
      formattedRemaining: _moneyService.format(max(0, combined.remaining) / 100),
    );
  }

  MyBudgetSlicePresentationData _toMySlice(BudgetSliceModel slice) {
    final percentage = slice.value > 0 ? slice.totalSpent / slice.value : 0.0;
    return MyBudgetSlicePresentationData(
      percentage: percentage,
      formattedValue: _moneyService.format(slice.value / 100),
      formattedSpent: _moneyService.format(slice.totalSpent / 100),
      formattedRemaining: _moneyService.format(max(0, slice.remaining) / 100),
    );
  }

  PartnerBudgetSlicePresentationData _toPartnerSlice(
    PartnerBudgetSliceModel slice,
  ) {
    final percentage = slice.value > 0 ? slice.totalSpent / slice.value : 0.0;
    return PartnerBudgetSlicePresentationData(
      percentage: percentage,
      partnerName: slice.name,
      formattedValue: _moneyService.format(slice.value / 100),
      formattedSpent: _moneyService.format(slice.totalSpent / 100),
      formattedRemaining: _moneyService.format(max(0, slice.remaining) / 100),
    );
  }
}
