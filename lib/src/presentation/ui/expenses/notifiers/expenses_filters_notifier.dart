import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
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
    PresetSelected(:final preset) => _selectPreset(preset),
    CustomRangeChanged(:final startDate, :final endDate) => _applyCustomRange(
      startDate,
      endDate,
    ),
    MinValueChanged(:final cents) => state = state.copyWith(
      draft: state.draft.copyWith(
        minValue: cents,
        clearMinValue: cents == null || cents == 0,
      ),
    ),
    MaxValueChanged(:final cents) => state = state.copyWith(
      draft: state.draft.copyWith(
        maxValue: cents,
        clearMaxValue: cents == null || cents == 0,
      ),
    ),
    OrderingSelected(:final ordering) => state = state.copyWith(
      draft: state.draft.copyWith(ordering: ordering),
    ),
    Cleared() => state = const ExpensesFiltersState(),
  };

  void _selectPreset(ExpensePeriodPresetEnum preset) {
    if (preset == ExpensePeriodPresetEnum.custom) {
      state = state.copyWith(selectedPreset: preset);
      return;
    }

    final range = preset.toRange(now: _now());
    final draft = state.draft.copyWith(
      endDate: range.endDate,
      startDate: range.startDate,
    );

    state = state.copyWith(
      draft: draft,
      selectedPreset: preset,
      formattedPeriodSummary: _summaryOf(draft),
    );
  }

  void _applyCustomRange(int? startDate, int? endDate) {
    final draft = state.draft.copyWith(
      endDate: endDate,
      startDate: startDate,
    );

    state = state.copyWith(
      draft: draft,
      selectedPreset: ExpensePeriodPresetEnum.custom,
      formattedPeriodSummary: _summaryOf(draft),
    );
  }

  String? _summaryOf(ExpenseFilterModel draft) {
    if (draft.startDate == null || draft.endDate == null) return null;

    return _dateFormatter.formatPeriod(draft.startDate!, draft.endDate!);
  }
}
