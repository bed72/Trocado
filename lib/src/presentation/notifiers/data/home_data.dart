import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:trocado/src/domain/models/entry_model.dart';

import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/notifiers/data/month_data.dart';

@immutable
final class HomeData extends Equatable {
  final MonthData month;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final BalanceModel balance;
  final List<TransactionModel> transactions;

  final EntryModel? filter;

  const HomeData({
    required this.month,
    required this.filter,
    required this.balance,
    required this.transactions,
    required this.isLoadingMore,
    required this.hasReachedEnd,
  });

  factory HomeData.empty() => HomeData(
    filter: null,
    isLoadingMore: false,
    hasReachedEnd: false,
    transactions: const [],
    month: MonthData.now(),
    balance: BalanceModel.empty(),
  );

  HomeData copyWith({
    MonthData? month,
    EntryModel? filter,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    BalanceModel? balance,
    List<TransactionModel>? transactions,
  }) => HomeData(
    month: month ?? this.month,
    filter: filter ?? this.filter,
    balance: balance ?? this.balance,
    transactions: transactions ?? this.transactions,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
  );

  @override
  List<Object?> get props => [
    month,
    filter,
    balance,
    transactions,
    isLoadingMore,
    hasReachedEnd,
  ];
}
