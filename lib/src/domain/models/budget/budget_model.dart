import 'package:equatable/equatable.dart';

final class BudgetModel extends Equatable {
  final int id;
  final int value;
  final int endDate;
  final int startDate;
  final String description;
  final int? totalSpent;
  final int? remaining;
  final int? createdAt;

  const BudgetModel({
    required this.id,
    required this.value,
    required this.endDate,
    required this.startDate,
    required this.description,
    this.totalSpent,
    this.remaining,
    this.createdAt,
  });

  BudgetModel copyWith({
    int? id,
    int? value,
    int? endDate,
    int? startDate,
    String? description,
    int? totalSpent,
    int? remaining,
    int? createdAt,
  }) => BudgetModel(
    id: id ?? this.id,
    value: value ?? this.value,
    endDate: endDate ?? this.endDate,
    startDate: startDate ?? this.startDate,
    description: description ?? this.description,
    totalSpent: totalSpent ?? this.totalSpent,
    remaining: remaining ?? this.remaining,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    value,
    startDate,
    endDate,
    description,
    totalSpent,
    remaining,
    createdAt,
  ];
}
