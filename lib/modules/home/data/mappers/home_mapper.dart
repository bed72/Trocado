import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/domain/models/balance_model.dart';
import 'package:trocado/modules/home/infrastructure/entities/balance_entity.dart';

class BalanceOutMapper implements Mapper<BalanceEntity, BalanceModel> {
  @override
  BalanceModel call(BalanceEntity parameter) => BalanceModel(
    total: parameter.total,
    income: parameter.income,
    expense: parameter.expense,
  );
}
