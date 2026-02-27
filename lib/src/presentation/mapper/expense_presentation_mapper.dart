import 'package:trocado/src/data/mapper/mapper.dart';

import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/presentation/data/ui/expense_presentation_data.dart';

class ExpensePresentationToModelMapper
    implements Mapper<ExpensePresentationData, ExpenseModel> {
  @override
  ExpenseModel call(ExpensePresentationData parameter) => ExpenseModel(
    amount: parameter.amount,
    category: parameter.category.name,
    description: parameter.description,
    date: parameter.date.millisecondsSinceEpoch,
  );
}
