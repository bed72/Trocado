import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transaction/infrastructure/database/entities/transaction_entity.dart';

abstract interface class ITransactionLocalDatasource {
  Either<String, void> delete(int id);
  Either<String, TransactionEntity> find(int id);
  Either<String, void> save(TransactionEntity entity);
  Either<String, void> update(TransactionEntity entity);
}
