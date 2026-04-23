import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/enums/expense/expense_ordering_enum.dart';

final class ExpenseFilterModel extends Equatable {
  final int? endDate;
  final int? minValue;
  final int? maxValue;
  final int? startDate;
  final String description;
  final ExpenseOrderingEnum ordering;
  final ExpenseCategoryEnum? category;

  const ExpenseFilterModel({
    this.endDate,
    this.category,
    this.minValue,
    this.maxValue,
    this.startDate,
    this.description = '',
    this.ordering = .dateDesc,
  });

  const ExpenseFilterModel.empty() : this();

  bool get isEmpty =>
      endDate == null &&
      minValue == null &&
      maxValue == null &&
      category == null &&
      startDate == null &&
      description.isEmpty &&
      ordering == .dateDesc;

  ExpenseFilterModel normalized() {
    final min = minValue;
    final max = maxValue;
    if (min == null || max == null || min <= max) return this;

    return copyWith(minValue: max, maxValue: min);
  }

  ExpenseFilterModel copyWith({
    int? endDate,
    int? minValue,
    int? maxValue,
    int? startDate,
    String? description,
    ExpenseCategoryEnum? category,
    ExpenseOrderingEnum? ordering,
    bool clearEndDate = false,
    bool clearCategory = false,
    bool clearMinValue = false,
    bool clearMaxValue = false,
    bool clearStartDate = false,
  }) => ExpenseFilterModel(
    ordering: ordering ?? this.ordering,
    description: description ?? this.description,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    minValue: clearMinValue ? null : minValue ?? this.minValue,
    maxValue: clearMaxValue ? null : maxValue ?? this.maxValue,
    category: clearCategory ? null : category ?? this.category,
    startDate: clearStartDate ? null : startDate ?? this.startDate,
  );

  @override
  List<Object?> get props => [
    endDate,
    category,
    minValue,
    maxValue,
    ordering,
    startDate,
    description,
  ];
}
