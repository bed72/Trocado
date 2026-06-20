import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_state.dart';

import 'package:trocado/src/presentation/ui/budget/validators/budget_value_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_date_range_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_description_validation.dart';

final class BudgetFormValidator {
  final BudgetValueValidation _valueValidation;
  final BudgetDateRangeValidation _dateRangeValidation;
  final BudgetDescriptionValidation _descriptionValidation;

  const BudgetFormValidator({
    required this._valueValidation,
    required this._dateRangeValidation,
    required this._descriptionValidation,
  });

  ({BudgetFormState state, bool isValid}) call(BudgetFormState state) {
    final value = _valueValidation(state.value);
    final description = _descriptionValidation(state.description);
    final dateRange = _dateRangeValidation((state.startDate, state.endDate));

    final isValid =
        value is Valid && description is Valid && dateRange is Valid;

    final validated = state.copyWith(
      valueFailure: switch (value) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      descriptionFailure: switch (description) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      dateFailure: switch (dateRange) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearValueFailure: value is Valid,
      clearDateFailure: dateRange is Valid,
      clearDescriptionFailure: description is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
