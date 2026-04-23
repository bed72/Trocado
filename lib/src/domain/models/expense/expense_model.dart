import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

final class ExpenseModel extends Equatable {
  final int id;
  final int date;
  final int value;
  final int createdAt;
  final String description;
  final ExpenseCategoryEnum category;

  const ExpenseModel({
    required this.id,
    required this.date,
    required this.value,
    required this.category,
    required this.createdAt,
    required this.description,
  });

  ExpenseModel copyWith({
    int? id,
    int? date,
    int? value,
    int? createdAt,
    String? description,
    ExpenseCategoryEnum? category,
  }) => ExpenseModel(
    id: id ?? this.id,
    date: date ?? this.date,
    value: value ?? this.value,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    description: description ?? this.description,
  );

  @override
  List<Object?> get props => [
    id,
    value,
    date,
    description,
    category,
    createdAt,
  ];
}
