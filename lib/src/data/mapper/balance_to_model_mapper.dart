import 'package:trocado/src/domain/mappers/mapper.dart';

import 'package:trocado/src/domain/models/balance_model.dart';

import 'package:trocado/src/infrastructure/database/entities/balance_entity.dart';

class BalanceToModelMapper implements Mapper<BalanceEntity, BalanceModel> {
  @override
  BalanceModel call(BalanceEntity parameter) => BalanceModel(
    total: parameter.total,
    income: parameter.income,
    expense: parameter.expense,
  );
}
