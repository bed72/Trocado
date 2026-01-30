import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/balance_model.dart';

abstract interface class IHomeRepository {
  TransactionDto toTransactionDto(TransactionModel model);

  Either<String, void> deleteTransactionBy(int id);
  Either<String, BalanceModel> getBalanceBy({int? startAt, int? endAt});
  Either<String, List<TransactionModel>> findTransactionBy({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeModel? type,
  });
}
