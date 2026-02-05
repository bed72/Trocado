import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:trocado/src/domain/models/entry_model.dart';

import 'package:trocado/src/domain/models/month_model.dart';
import 'package:trocado/src/domain/models/balance_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

@immutable
final class HomeContentData extends Equatable {
  final MonthModel month;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final BalanceModel balance;
  final List<TransactionModel> transactions;

  final EntryModel? filter;

  const HomeContentData({
    required this.month,
    required this.filter,
    required this.balance,
    required this.transactions,
    required this.isLoadingMore,
    required this.hasReachedEnd,
  });

  factory HomeContentData.empty() => HomeContentData(
    filter: null,
    isLoadingMore: false,
    hasReachedEnd: false,
    transactions: const [],
    month: MonthModel.now(),
    balance: BalanceModel.empty(),
  );

  HomeContentData copyWith({
    MonthModel? month,
    EntryModel? filter,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    BalanceModel? balance,
    List<TransactionModel>? transactions,
  }) => HomeContentData(
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
