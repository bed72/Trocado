import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/screens/expense/notifiers/expense_state.dart';
import 'package:trocado/src/presentation/screens/expense/validators/expense_date_validation.dart';
import 'package:trocado/src/presentation/screens/expense/validators/expense_value_validation.dart';
import 'package:trocado/src/presentation/screens/expense/validators/expense_description_validation.dart';

final class ExpenseFormValidator {
  final ExpenseDateValidation _dateValidation;
  final ExpenseValueValidation _valueValidation;
  final ExpenseDescriptionValidation _descriptionValidation;

  const ExpenseFormValidator({
    required ExpenseDateValidation dateValidation,
    required ExpenseValueValidation valueValidation,
    required ExpenseDescriptionValidation descriptionValidation,
  }) : _dateValidation = dateValidation,
       _valueValidation = valueValidation,
       _descriptionValidation = descriptionValidation;

  ({ExpenseState state, bool isValid}) call(ExpenseState state) {
    final date = _dateValidation(state.date);
    final value = _valueValidation(state.value);
    final description = _descriptionValidation(state.description);

    final isValid = value is Valid && description is Valid && date is Valid;

    final validated = state.copyWith(
      valueFailure: switch (value) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      descriptionFailure: switch (description) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      dateFailure: switch (date) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearDateFailure: date is Valid,
      clearValueFailure: value is Valid,
      clearDescriptionFailure: description is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
