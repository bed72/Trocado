import 'package:trocado/src/data/mapper/mapper.dart';

import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';

class ExpenseEntityToModelMapper
    implements Mapper<ExpenseEntity, ExpenseModel> {
  @override
  ExpenseModel call(ExpenseEntity parameter) => ExpenseModel(
    id: parameter.id,
    date: parameter.date,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
  );
}

class ExpenseModelToEntityMapper
    implements Mapper<ExpenseModel, ExpenseEntity> {
  @override
  ExpenseEntity call(ExpenseModel parameter) => ExpenseEntity(
    id: parameter.id,
    date: parameter.date,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
  );
}
