import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  Either<String, void> deleteTransactionById(int id);
  Either<String, TransactionModel> findTransactionById(int id);
  Either<String, void> saveTransactionByModel(TransactionModel model);
  Either<String, BalanceModel> getBalanceBy({int? startAt, int? endAt});
  Either<String, List<TransactionModel>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeModel? type,
  });
}
