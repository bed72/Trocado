import 'package:trocado/src/data/mapper/mapper.dart';

import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

class TransactionToModelMapper
    implements Mapper<TransactionEntity, TransactionModel> {
  @override
  TransactionModel call(TransactionEntity parameter) => TransactionModel(
    id: parameter.id,
    date: parameter.date,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
  );
}
