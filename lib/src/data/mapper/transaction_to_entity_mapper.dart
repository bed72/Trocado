import 'package:trocado/src/domain/mappers/mapper.dart';

import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/infrastructure/database/entities/transaction_entity.dart';

class TransactionToEntityMapper
    implements Mapper<TransactionModel, TransactionEntity> {
  @override
  TransactionEntity call(TransactionModel parameter) => TransactionEntity(
    date: parameter.date,
    type: parameter.type,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
    observation: parameter.observation,
  );
}
