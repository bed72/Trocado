import 'package:trocado/src/domain/models/expense/expense_category.dart';
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

sealed class ExpensesFiltersIntent {
  const ExpensesFiltersIntent();
}

final class InitializeFrom extends ExpensesFiltersIntent {
  final ExpenseFilterModel filter;
  const InitializeFrom(this.filter);
}

final class CategorySelected extends ExpensesFiltersIntent {
  final ExpenseCategory? category;
  const CategorySelected(this.category);
}

final class PresetSelected extends ExpensesFiltersIntent {
  final ExpensePeriodPreset preset;
  const PresetSelected(this.preset);
}

final class CustomRangeChanged extends ExpensesFiltersIntent {
  final int endDate;
  final int startDate;
  const CustomRangeChanged(this.startDate, this.endDate);
}

final class MinValueChanged extends ExpensesFiltersIntent {
  final int? cents;
  const MinValueChanged(this.cents);
}

final class MaxValueChanged extends ExpensesFiltersIntent {
  final int? centavos;
  const MaxValueChanged(this.centavos);
}

final class OrderingSelected extends ExpensesFiltersIntent {
  final ExpenseOrdering ordering;
  const OrderingSelected(this.ordering);
}

final class Cleared extends ExpensesFiltersIntent {
  const Cleared();
}
