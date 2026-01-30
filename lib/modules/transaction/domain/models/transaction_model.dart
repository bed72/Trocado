import 'package:equatable/equatable.dart';

enum TransactionTypeModel {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeModel(this.label);

  static TransactionTypeModel fromByInt(int value) => switch (value) {
    0 => .income,
    _ => .expense,
  };

  static TransactionTypeModel fromByString(String value) => .values.firstWhere(
    (transaction) => transaction.label == value,
    orElse: () => .expense,
  );
}

final class TransactionModel extends Equatable {
  final int date;
  final String type;
  final double amount;
  final String category;
  final String description;

  final int? id;
  final String? observation;

  const TransactionModel({
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
    this.observation,
  });

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    amount,
    category,
    description,
    observation,
  ];
}
