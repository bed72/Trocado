sealed class BudgetIntent {
  const BudgetIntent();
}

final class ValueChanged extends BudgetIntent {
  final int value;
  const ValueChanged(this.value);
}

final class DateRangeChanged extends BudgetIntent {
  final int startDate;
  final int endDate;
  const DateRangeChanged({required this.startDate, required this.endDate});
}

final class DescriptionChanged extends BudgetIntent {
  final String value;
  const DescriptionChanged(this.value);
}

final class SubmitPressed extends BudgetIntent {
  const SubmitPressed();
}
