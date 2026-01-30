import 'package:equatable/equatable.dart';

import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/balance_model.dart';

final class HomeModel extends Equatable {
  final BalanceModel balance;
  final List<TransactionModel> transactions;

  const HomeModel({required this.balance, required this.transactions});

  HomeModel removeTransactionBy(int id) => HomeModel(
    balance: balance,
    transactions: transactions
        .where((transaction) => transaction.id != id)
        .toList(),
  );

  HomeModel copyWith({
    BalanceModel? balance,
    List<TransactionModel>? transactions,
  }) => HomeModel(
    balance: balance ?? this.balance,
    transactions: transactions ?? this.transactions,
  );

  @override
  List<Object?> get props => [balance, transactions];
}
