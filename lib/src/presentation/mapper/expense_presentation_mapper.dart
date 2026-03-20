import 'package:trocado/src/domain/contracts/mapper.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

import 'package:trocado/src/presentation/data/expense_presentation_data.dart';
import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

class ExpenseModelToPresentationMapper
    implements Mapper<ExpenseModel, ExpensePresentationData> {
  @override
  ExpensePresentationData call(ExpenseModel parameter) =>
      ExpensePresentationData(
        id: parameter.id,
        amount: parameter.amount,
        description: parameter.description,
        category: .fromName(parameter.category),
        date: DateTime.fromMillisecondsSinceEpoch(parameter.date).format(),
      );
}

class ExpenseStateToModelMapper
    implements Mapper<ExpenseFormState, ExpenseModel> {
  @override
  ExpenseModel call(ExpenseFormState parameter) => ExpenseModel(
    amount: parameter.amount / 100,
    category: parameter.category.name,
    description: parameter.description,
    date: parameter.date.millisecondsSinceEpoch,
  );
}
