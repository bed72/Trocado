import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  TransactionDto toTransactionDto(TransactionModel model);

  Either<String, void> delete(int id);
  Either<String, TransactionModel> find(int id);
  Either<String, void> save(TransactionDto dto);
}
