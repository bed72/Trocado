sealed class BudgetEvent {
  const BudgetEvent();
}

final class BudgetLoaded extends BudgetEvent {
  const BudgetLoaded();
}

final class BudgetCreated extends BudgetEvent {
  final int endDate;
  final int startDate;
  final double amount;
  final String? description;

  const BudgetCreated({
    required this.amount,
    required this.endDate,
    required this.startDate,
    this.description,
  });
}

final class BudgetRecalculated extends BudgetEvent {
  const BudgetRecalculated();
}
