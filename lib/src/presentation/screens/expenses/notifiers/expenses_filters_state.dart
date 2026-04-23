import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

final class ExpensesFiltersState extends Equatable {
  final ExpenseFilterModel draft;
  final ExpensePeriodPresetEnum? selectedPreset;

  const ExpensesFiltersState({
    this.draft = const .empty(),
    this.selectedPreset,
  });

  ExpensesFiltersState copyWith({
    ExpenseFilterModel? draft,
    bool clearSelectedPreset = false,
    ExpensePeriodPresetEnum? selectedPreset,
  }) => ExpensesFiltersState(
    draft: draft ?? this.draft,
    selectedPreset: clearSelectedPreset
        ? null
        : selectedPreset ?? this.selectedPreset,
  );

  @override
  List<Object?> get props => [draft, selectedPreset];
}
