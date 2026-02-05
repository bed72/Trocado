import 'package:trocado/src/data/mapper/mapper.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

class TransactionToEntityMapper
    implements Mapper<TransactionModel, TransactionEntity> {
  @override
  TransactionEntity call(TransactionModel parameter) => TransactionEntity(
    id: parameter.id,
    date: parameter.date,
    type: parameter.type,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
    observation: parameter.observation,
  );
}
