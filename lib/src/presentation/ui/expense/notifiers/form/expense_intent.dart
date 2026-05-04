sealed class ExpenseIntent {
  const ExpenseIntent();
}

final class ValueChanged extends ExpenseIntent {
  final int value;
  const ValueChanged(this.value);
}

final class DescriptionChanged extends ExpenseIntent {
  final String value;
  const DescriptionChanged(this.value);
}

final class DateChanged extends ExpenseIntent {
  final int date;
  const DateChanged(this.date);
}

final class SubmitPressed extends ExpenseIntent {
  const SubmitPressed();
}

final class DeletePressed extends ExpenseIntent {
  const DeletePressed();
}
