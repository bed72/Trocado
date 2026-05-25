import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_value_preset_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_state.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart';

part 'expenses_filters_notifier.g.dart';

@Riverpod()
final class ExpensesFiltersNotifier extends _$ExpensesFiltersNotifier {
  late DateTime Function() _now;
  late IDateFormatterService _dateFormatter;

  @override
  ExpensesFiltersState build(ExpenseFilterModel seed) {
    _now = ref.watch(nowProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    return ExpensesFiltersState(
      draft: seed,
      formattedPeriodSummary: _summaryOf(seed),
    );
  }

  void dispatch(ExpensesFiltersIntent intent) => switch (intent) {
    CategorySelected(:final category) => state = state.copyWith(
      draft: state.draft.copyWith(
        category: category,
        clearCategory: category == null,
      ),
    ),
    ValuePresetSelected(:final preset) => _selectValuePreset(preset),
    PeriodPresetSelected(:final preset) => _selectPeriodPreset(preset),
    CustomRangeChanged(:final startDate, :final endDate) => _applyCustomRange(
      startDate,
      endDate,
    ),
    Cleared() => state = const ExpensesFiltersState(),
  };

  void _selectValuePreset(ExpenseValuePresetEnum preset) {
    final range = preset.toRange();
    final draft = state.draft.copyWith(
      minValue: range.minValue,
      maxValue: range.maxValue,
      clearMinValue: range.minValue == null,
      clearMaxValue: range.maxValue == null,
    );

    state = state.copyWith(draft: draft, selectedValuePreset: preset);
  }

  void _selectPeriodPreset(ExpensePeriodPresetEnum preset) {
    if (preset == .custom) {
      state = state.copyWith(selectedPeriodPreset: preset);
      return;
    }

    final range = preset.toRange(now: _now());
    final draft = state.draft.copyWith(
      endDate: range.endDate,
      startDate: range.startDate,
    );

    state = state.copyWith(
      draft: draft,
      selectedPeriodPreset: preset,
      formattedPeriodSummary: _summaryOf(draft),
    );
  }

  void _applyCustomRange(int? startDate, int? endDate) {
    final draft = state.draft.copyWith(endDate: endDate, startDate: startDate);

    state = state.copyWith(
      draft: draft,
      selectedPeriodPreset: ExpensePeriodPresetEnum.custom,
      formattedPeriodSummary: _summaryOf(draft),
    );
  }

  String? _summaryOf(ExpenseFilterModel draft) {
    if (draft.startDate == null || draft.endDate == null) return null;

    return _dateFormatter.formatPeriod(draft.startDate!, draft.endDate!);
  }
}
