import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/models/transaction_model.dart';

abstract interface class ITransactionRepository {
  Either<String, void> delete(int id);
  Either<String, TransactionModel> find(int id);
  Either<String, void> save(TransactionModel dto);
}
