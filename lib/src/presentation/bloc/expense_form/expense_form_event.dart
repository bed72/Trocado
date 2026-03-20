import 'package:trocado/src/presentation/data/category_presentation_data.dart';

sealed class ExpenseFormEvent {
  const ExpenseFormEvent();
}

final class ExpenseDateChanged extends ExpenseFormEvent {
  final DateTime date;
  const ExpenseDateChanged(this.date);
}

final class ExpenseCategoryChanged extends ExpenseFormEvent {
  final CategoryPresentationData category;
  const ExpenseCategoryChanged(this.category);
}

final class ExpenseDescriptionChanged extends ExpenseFormEvent {
  final String value;
  const ExpenseDescriptionChanged(this.value);
}

final class ExpenseAmountCleared extends ExpenseFormEvent {
  const ExpenseAmountCleared();
}

final class ExpenseAmountDigitPressed extends ExpenseFormEvent {
  final String digit;
  const ExpenseAmountDigitPressed(this.digit);
}

final class ExpenseAmountDeletePressed extends ExpenseFormEvent {
  const ExpenseAmountDeletePressed();
}

final class ExpenseFormReset extends ExpenseFormEvent {
  const ExpenseFormReset();
}

final class ExpenseFormSubmitted extends ExpenseFormEvent {
  const ExpenseFormSubmitted();
}
