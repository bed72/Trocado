import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/category_model.dart';

@immutable
final class TransactionData extends Equatable {
  final double amount;
  final DateTime date;
  final String formattedDate;
  final CategoryModel category;

  const TransactionData({
    required this.date,
    required this.amount,
    required this.category,
    required this.formattedDate,
  });

  factory TransactionData.empty() => TransactionData(
    amount: 0.0,
    date: .now(),
    category: .other,
    formattedDate: '',
  );

  TransactionData copyWith({
    double? amount,
    DateTime? date,
    String? formattedDate,
    CategoryModel? category,
  }) => TransactionData(
    date: date ?? this.date,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    formattedDate: formattedDate ?? this.formattedDate,
  );

  @override
  List<Object?> get props => [amount, date, formattedDate, category];
}
