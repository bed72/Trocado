import 'package:trocado/src/domain/models/entry_model.dart';
import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/domain/repositories/interface_balance_repository.dart';

final class BalanceRepsository implements IBalanceRepository {
  @override
  BalanceModel calculate(List<TransactionModel> transactions) {
    final income = transactions
        .where((transaction) => transaction.type == EntryModel.income.name)
        .fold(0.0, (a, b) => a + b.amount);

    final expense = transactions
        .where((transaction) => transaction.type == EntryModel.expense.name)
        .fold(0.0, (a, b) => a + b.amount);

    return BalanceModel(income: income, expense: expense);
  }
}
