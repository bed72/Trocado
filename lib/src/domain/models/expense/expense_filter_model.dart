import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

final class ExpenseFilterModel extends Equatable {
  final int? endDate;
  final int? startDate;
  final String description;
  final ExpenseCategoryEnum? category;

  const ExpenseFilterModel({
    this.endDate,
    this.category,
    this.startDate,
    this.description = '',
  });

  const ExpenseFilterModel.empty() : this();

  bool get isEmpty =>
      endDate == null &&
      category == null &&
      startDate == null &&
      description.isEmpty;

  ExpenseFilterModel copyWith({
    int? endDate,
    int? startDate,
    String? description,
    ExpenseCategoryEnum? category,
    bool clearEndDate = false,
    bool clearCategory = false,
    bool clearStartDate = false,
  }) => ExpenseFilterModel(
    description: description ?? this.description,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    category: clearCategory ? null : category ?? this.category,
    startDate: clearStartDate ? null : startDate ?? this.startDate,
  );

  @override
  List<Object?> get props => [
    endDate,
    category,
    startDate,
    description,
  ];
}
