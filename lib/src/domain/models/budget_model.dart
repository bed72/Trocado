import 'package:equatable/equatable.dart';

final class BudgetModel extends Equatable {
  final int? id;
  final double amount;
  final int startDate;
  final int endDate;
  final String? description;

  const BudgetModel({
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.id,
    this.description,
  });

  @override
  List<Object?> get props => [id, amount, startDate, endDate, description];
}
