import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/entry_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  Either<String, void> deleteById(int id);
  Either<String, TransactionModel> findById(int id);
  Either<String, void> upsert(TransactionModel model);
  Either<String, List<TransactionModel>> findByEntry(EntryModel model);
  Either<String, List<TransactionModel>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  });
}
