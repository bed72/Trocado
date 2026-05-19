import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_value_preset_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

final class ExpensesFiltersState extends Equatable {
  final ExpenseFilterModel draft;
  final String? formattedPeriodSummary;
  final ExpenseValuePresetEnum? selectedValuePreset;
  final ExpensePeriodPresetEnum? selectedPeriodPreset;

  const ExpensesFiltersState({
    this.selectedValuePreset,
    this.selectedPeriodPreset,
    this.formattedPeriodSummary,
    this.draft = const .empty(),
  });

  ExpensesFiltersState copyWith({
    ExpenseFilterModel? draft,
    String? formattedPeriodSummary,
    ExpenseValuePresetEnum? selectedValuePreset,
    ExpensePeriodPresetEnum? selectedPeriodPreset,
    bool clearSelectedValuePreset = false,
    bool clearSelectedPeriodPreset = false,
    bool clearFormattedPeriodSummary = false,
  }) => ExpensesFiltersState(
    draft: draft ?? this.draft,
    selectedValuePreset: clearSelectedValuePreset
        ? null
        : selectedValuePreset ?? this.selectedValuePreset,
    selectedPeriodPreset: clearSelectedPeriodPreset
        ? null
        : selectedPeriodPreset ?? this.selectedPeriodPreset,
    formattedPeriodSummary: clearFormattedPeriodSummary
        ? null
        : formattedPeriodSummary ?? this.formattedPeriodSummary,
  );

  @override
  List<Object?> get props => [
    draft,
    selectedValuePreset,
    selectedPeriodPreset,
    formattedPeriodSummary,
  ];
}
