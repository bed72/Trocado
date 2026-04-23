import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_state.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart';

part 'expenses_filters_notifier.g.dart';

@riverpod
final class ExpensesFiltersNotifier extends _$ExpensesFiltersNotifier {
  late DateTime Function() _now;

  @override
  ExpensesFiltersState build() {
    _now = ref.watch(nowProvider);

    return const ExpensesFiltersState();
  }

  void dispatch(ExpensesFiltersIntent intent) => switch (intent) {
    InitializeFrom(:final filter) => state = ExpensesFiltersState(
      draft: filter,
    ),
    CategorySelected(:final category) => state = state.copyWith(
      draft: state.draft.copyWith(
        category: category,
        clearCategory: category == null,
      ),
    ),
    PresetSelected(:final preset) => _selectPreset(preset),
    CustomRangeChanged(:final startDate, :final endDate) =>
      state = state.copyWith(
        selectedPreset: ExpensePeriodPresetEnum.custom,
        draft: state.draft.copyWith(startDate: startDate, endDate: endDate),
      ),
    MinValueChanged(cents: final centavos) => state = state.copyWith(
      draft: state.draft.copyWith(
        minValue: centavos,
        clearMinValue: centavos == null || centavos == 0,
      ),
    ),
    MaxValueChanged(:final centavos) => state = state.copyWith(
      draft: state.draft.copyWith(
        maxValue: centavos,
        clearMaxValue: centavos == null || centavos == 0,
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
    state = state.copyWith(
      selectedPreset: preset,
      draft: state.draft.copyWith(
        endDate: range.endDate,
        startDate: range.startDate,
      ),
    );
  }
}
