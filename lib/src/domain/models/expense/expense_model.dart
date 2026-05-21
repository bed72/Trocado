import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

final class ExpenseModel extends Equatable {
  final int id;
  final int date;
  final int value;
  final int createdAt;
  final bool? createdByMe;
  final String description;
  final String? createdByName;
  final ExpenseCategoryEnum category;

  const ExpenseModel({
    required this.id,
    required this.date,
    required this.value,
    required this.category,
    required this.createdAt,
    required this.description,
    this.createdByMe,
    this.createdByName,
  });

  ExpenseModel copyWith({
    int? id,
    int? date,
    int? value,
    int? createdAt,
    String? description,
    bool? createdByMe,
    String? createdByName,
    ExpenseCategoryEnum? category,
  }) => ExpenseModel(
    id: id ?? this.id,
    date: date ?? this.date,
    value: value ?? this.value,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    description: description ?? this.description,
    createdByMe: createdByMe ?? this.createdByMe,
    createdByName: createdByName ?? this.createdByName,
  );

  @override
  List<Object?> get props => [
    id,
    value,
    date,
    category,
    createdAt,
    description,
    createdByMe,
    createdByName,
  ];
}
