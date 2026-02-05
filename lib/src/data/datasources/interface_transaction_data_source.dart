import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/database/entities/transaction_entity.dart';

abstract interface class ITransactionDataSource {
  Either<String, void> deleteById(int id);
  Either<String, TransactionEntity> findById(int id);
  Either<String, void> upsert(TransactionEntity entity);
  Either<String, List<TransactionEntity>> findByEntry(String entry);
  Either<String, List<TransactionEntity>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  });
}
