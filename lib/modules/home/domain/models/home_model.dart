import 'package:equatable/equatable.dart';

import 'package:trocado/modules/transaction/transaction.dart';

final class HomeModel extends Equatable {
  final List<TransactionModel> transactions;

  const HomeModel({required this.transactions});

  HomeModel removeBy(int id) => HomeModel(
    transactions: transactions
        .where((transaction) => transaction.id != id)
        .toList(),
  );

  HomeModel copyWith({List<TransactionModel>? transactions}) =>
      HomeModel(transactions: transactions ?? this.transactions);

  @override
  List<Object?> get props => [transactions];
}
