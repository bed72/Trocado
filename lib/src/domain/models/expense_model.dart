import 'package:equatable/equatable.dart';

final class ExpenseModel extends Equatable {
  final int date;
  final double amount;
  final String category;
  final String description;

  final int? id;

  const ExpenseModel({
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
  });

  @override
  List<Object?> get props => [id, date, amount, category, description];
}
