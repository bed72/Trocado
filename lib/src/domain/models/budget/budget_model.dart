import 'package:equatable/equatable.dart';

final class BudgetModel extends Equatable {
  final int id;
  final int value;
  final int endDate;
  final int startDate;
  final String description;
  final int? remaining;
  final int? createdAt;
  final int? totalSpent;

  const BudgetModel({
    required this.id,
    required this.value,
    required this.endDate,
    required this.startDate,
    required this.description,
    this.createdAt,
    this.remaining,
    this.totalSpent,
  });

  BudgetModel copyWith({
    int? id,
    int? value,
    int? endDate,
    int? startDate,
    int? remaining,
    int? createdAt,
    int? totalSpent,
    String? description,
  }) => BudgetModel(
    id: id ?? this.id,
    value: value ?? this.value,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    startDate: startDate ?? this.startDate,
    remaining: remaining ?? this.remaining,
    totalSpent: totalSpent ?? this.totalSpent,
    description: description ?? this.description,
  );

  @override
  List<Object?> get props => [
    id,
    value,
    endDate,
    createdAt,
    startDate,
    remaining,
    totalSpent,
    description,
  ];
}
