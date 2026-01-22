import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

class TransactionDtoMapper implements Mapper<TransactionModel, TransactionDto> {
  @override
  TransactionDto call(TransactionModel parameter) => TransactionDto(
    amount: parameter.amount,
    description: parameter.description,
    observation: parameter.observation,
    type: .fromByString(parameter.type),
    category: .fromByString(parameter.category),
    date: dateTimeFromMilliseconds(parameter.date),
  );
}

class TransactionInMapper implements Mapper<TransactionDto, TransactionEntity> {
  @override
  TransactionEntity call(TransactionDto parameter) => TransactionEntity(
    amount: parameter.amount,
    type: parameter.type.label,
    category: parameter.category.label,
    description: parameter.description,
    observation: parameter.observation,
    date: parameter.date.millisecondsSinceEpoch,
  );
}

class TransactionOutMapper
    implements Mapper<TransactionEntity, TransactionModel> {
  @override
  TransactionModel call(TransactionEntity parameter) => TransactionModel(
    id: parameter.id,
    date: parameter.date,
    type: parameter.type,
    amount: parameter.amount,
    category: parameter.category,
    description: parameter.description,
    observation: parameter.observation,
  );
}
