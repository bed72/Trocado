import 'package:flutter/foundation.dart';

@immutable
final class BalanceModel {
  final double income;
  final double expense;

  const BalanceModel({required this.income, required this.expense});

  double get total => income - expense;

  factory BalanceModel.empty() => BalanceModel(income: 0, expense: 0);
}
