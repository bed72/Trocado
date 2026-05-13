import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

final class ExpensesFiltersState extends Equatable {
  final ExpenseFilterModel draft;
  final String? formattedPeriodSummary;
  final ExpensePeriodPresetEnum? selectedPreset;

  const ExpensesFiltersState({
    this.selectedPreset,
    this.formattedPeriodSummary,
    this.draft = const .empty(),
  });

  ExpensesFiltersState copyWith({
    ExpenseFilterModel? draft,
    String? formattedPeriodSummary,
    bool clearSelectedPreset = false,
    bool clearFormattedPeriodSummary = false,
    ExpensePeriodPresetEnum? selectedPreset,
  }) => ExpensesFiltersState(
    draft: draft ?? this.draft,
    selectedPreset: clearSelectedPreset
        ? null
        : selectedPreset ?? this.selectedPreset,
    formattedPeriodSummary: clearFormattedPeriodSummary
        ? null
        : formattedPeriodSummary ?? this.formattedPeriodSummary,
  );

  @override
  List<Object?> get props => [draft, selectedPreset, formattedPeriodSummary];
}
