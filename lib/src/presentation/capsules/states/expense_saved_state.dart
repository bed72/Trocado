sealed class ExpenseSavedState {
  const ExpenseSavedState();
}

final class ExpenseSavedSuccessState extends ExpenseSavedState {
  final String message;
  const ExpenseSavedSuccessState(this.message);
}

final class ExpenseSavedFailureState extends ExpenseSavedState {
  final String message;
  const ExpenseSavedFailureState(this.message);
}
