import 'package:trocado/src/data/mapper/mapper.dart';

import 'package:trocado/src/domain/models/budget_model.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

class BudgetEntityToModelMapper
    implements Mapper<BudgetEntity, BudgetModel> {
  @override
  BudgetModel call(BudgetEntity parameter) => BudgetModel(
    id: parameter.id,
    amount: parameter.amount,
    startDate: parameter.startDate,
    endDate: parameter.endDate,
    description: parameter.description,
  );
}

class BudgetModelToEntityMapper
    implements Mapper<BudgetModel, BudgetEntity> {
  @override
  BudgetEntity call(BudgetModel parameter) => BudgetEntity(
    id: parameter.id,
    amount: parameter.amount,
    startDate: parameter.startDate,
    endDate: parameter.endDate,
    description: parameter.description,
  );
}
