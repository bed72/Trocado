import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/data/ui/category_presentation_data.dart';

enum ExpenseFormStatus { initial, loading, success, failure }

@immutable
final class ExpenseFormState extends Equatable {
  final int amount;
  final DateTime date;
  final String? message;
  final bool hasFailure;
  final String description;
  final String formattedAmount;
  final ExpenseFormStatus status;
  final CategoryPresentationData category;

  const ExpenseFormState({
    required this.date,
    this.message,
    this.amount = 0,
    this.description = '',
    this.status = .initial,
    this.category = .other,
    this.hasFailure = false,
    this.formattedAmount = '',
  });

  bool get hasValidAmount => amount > 0;
  bool get hasValidDescription => description.trim().length >= 3;
  bool get isValid => hasValidAmount && hasValidDescription;

  String? get amountFailure =>
      hasFailure && !hasValidAmount ? 'Informe um valor maior que zero.' : null;

  String? get descriptionFailure => hasFailure && !hasValidDescription
      ? 'A descrição deve conter ao menos 3 letras.'
      : null;

  ExpenseFormState copyWith({
    int? amount,
    DateTime? date,
    String? message,
    bool? hasFailure,
    String? description,
    String? formattedAmount,
    ExpenseFormStatus? status,
    CategoryPresentationData? category,
  }) => ExpenseFormState(
    message: message,
    date: date ?? this.date,
    status: status ?? this.status,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    hasFailure: hasFailure ?? this.hasFailure,
    description: description ?? this.description,
    formattedAmount: formattedAmount ?? this.formattedAmount,
  );

  @override
  List<Object?> get props => [
    date,
    status,
    amount,
    message,
    category,
    hasFailure,
    description,
    formattedAmount,
  ];
}
