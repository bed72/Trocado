sealed class BudgetFormIntent {
  const BudgetFormIntent();
}

final class ValueChanged extends BudgetFormIntent {
  final int value;
  const ValueChanged(this.value);
}

final class DateRangeChanged extends BudgetFormIntent {
  final int endDate;
  final int startDate;
  const DateRangeChanged({required this.startDate, required this.endDate});
}

final class DescriptionChanged extends BudgetFormIntent {
  final String value;
  const DescriptionChanged(this.value);
}

final class SubmitPressed extends BudgetFormIntent {
  const SubmitPressed();
}
