import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

abstract interface class IBalanceRepository {
  BalanceModel calculate(List<TransactionModel> transactions);
}
