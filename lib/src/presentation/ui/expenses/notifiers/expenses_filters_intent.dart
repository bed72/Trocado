import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

sealed class ExpensesFiltersIntent {
  const ExpensesFiltersIntent();
}

final class CategorySelected extends ExpensesFiltersIntent {
  final ExpenseCategoryEnum? category;
  const CategorySelected(this.category);
}

final class PresetSelected extends ExpensesFiltersIntent {
  final ExpensePeriodPresetEnum preset;
  const PresetSelected(this.preset);
}

final class CustomRangeChanged extends ExpensesFiltersIntent {
  final int endDate;
  final int startDate;
  const CustomRangeChanged(this.startDate, this.endDate);
}

final class Cleared extends ExpensesFiltersIntent {
  const Cleared();
}
