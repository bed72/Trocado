import 'package:equatable/equatable.dart';

final class BudgetModel extends Equatable {
  final int? id;
  final int endDate;
  final double amount;
  final int startDate;
  final String? description;

  const BudgetModel({
    required this.amount,
    required this.endDate,
    required this.startDate,
    this.id,
    this.description,
  });

  @override
  List<Object?> get props => [id, amount, startDate, endDate, description];
}
