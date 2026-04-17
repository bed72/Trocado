import 'package:equatable/equatable.dart';

final class ActiveBudgetModel extends Equatable {
  final int id;
  final int value;
  final int startDate;
  final int endDate;
  final String description;
  final int totalSpent;
  final int remaining;

  const ActiveBudgetModel({
    required this.id,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.totalSpent,
    required this.remaining,
  });

  ActiveBudgetModel copyWith({
    int? id,
    int? value,
    int? startDate,
    int? endDate,
    String? description,
    int? totalSpent,
    int? remaining,
  }) => ActiveBudgetModel(
    id: id ?? this.id,
    value: value ?? this.value,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    description: description ?? this.description,
    totalSpent: totalSpent ?? this.totalSpent,
    remaining: remaining ?? this.remaining,
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
  ];
}
