import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

final class ExpensesFiltersState extends Equatable {
  final ExpenseFilterModel draft;
  final ExpensePeriodPreset? selectedPreset;

  const ExpensesFiltersState({
    this.draft = const .empty(),
    this.selectedPreset,
  });

  ExpensesFiltersState copyWith({
    ExpenseFilterModel? draft,
    bool clearSelectedPreset = false,
    ExpensePeriodPreset? selectedPreset,
  }) => ExpensesFiltersState(
    draft: draft ?? this.draft,
    selectedPreset: clearSelectedPreset
        ? null
        : selectedPreset ?? this.selectedPreset,
  );

  @override
  List<Object?> get props => [draft, selectedPreset];
}
