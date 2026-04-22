import 'package:equatable/equatable.dart';

final class ActiveBudgetModel extends Equatable {
  final int id;
  final int value;
  final int endDate;
  final int startDate;
  final int remaining;
  final int totalSpent;
  final String description;

  const ActiveBudgetModel({
    required this.id,
    required this.value,
    required this.endDate,
    required this.startDate,
    required this.remaining,
    required this.totalSpent,
    required this.description,
  });

  ActiveBudgetModel copyWith({
    int? id,
    int? value,
    int? endDate,
    int? startDate,
    int? remaining,
    int? totalSpent,
    String? description,
  }) => ActiveBudgetModel(
    id: id ?? this.id,
    value: value ?? this.value,
    endDate: endDate ?? this.endDate,
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
    startDate,
    remaining,
    totalSpent,
    description,
  ];
}
