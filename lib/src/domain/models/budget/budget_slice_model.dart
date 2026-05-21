import 'package:equatable/equatable.dart';

final class BudgetSliceModel extends Equatable {
  final int value;
  final int remaining;
  final int totalSpent;

  const BudgetSliceModel({
    required this.value,
    required this.remaining,
    required this.totalSpent,
  });

  BudgetSliceModel copyWith({int? value, int? remaining, int? totalSpent}) =>
      BudgetSliceModel(
        value: value ?? this.value,
        remaining: remaining ?? this.remaining,
        totalSpent: totalSpent ?? this.totalSpent,
      );

  @override
  List<Object?> get props => [value, remaining, totalSpent];
}
