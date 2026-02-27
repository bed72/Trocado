sealed class BudgetEvent {
  const BudgetEvent();
}

final class BudgetLoaded extends BudgetEvent {
  const BudgetLoaded();
}

final class BudgetCreated extends BudgetEvent {
  final double amount;
  final int startDate;
  final int endDate;
  final String? description;

  const BudgetCreated({
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.description,
  });
}

final class BudgetRecalculated extends BudgetEvent {
  const BudgetRecalculated();
}
