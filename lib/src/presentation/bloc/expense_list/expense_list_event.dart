sealed class ExpenseListEvent {
  const ExpenseListEvent();
}

final class ExpenseListStarted extends ExpenseListEvent {
  const ExpenseListStarted();
}

final class ExpenseListNextPageRequested extends ExpenseListEvent {
  const ExpenseListNextPageRequested();
}

final class ExpenseListRefreshRequested extends ExpenseListEvent {
  const ExpenseListRefreshRequested();
}
