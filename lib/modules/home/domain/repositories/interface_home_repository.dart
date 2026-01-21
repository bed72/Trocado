import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

abstract interface class IHomeRepository {
  Either<String, void> delete(int id);
  Either<String, List<TransactionModel>> findByPeriod({
    int? endAt,
    int? limit,
    int? offset,
    int? startAt,
    TransactionTypeDto? type,
  });
}
