import 'package:equatable/equatable.dart';

final class BudgetCardData extends Equatable {
  final bool overspent;
  final double percentage;
  final String formattedValue;
  final String formattedRemaining;
  final String formattedOverspent;
  final String formattedTotalSpent;
  final String formattedPercentage;
  final String formattedDailyBudget;

  const BudgetCardData({
    required this.overspent,
    required this.percentage,
    required this.formattedValue,
    required this.formattedRemaining,
    required this.formattedOverspent,
    required this.formattedTotalSpent,
    required this.formattedPercentage,
    required this.formattedDailyBudget,
  });

  @override
  List<Object?> get props => [
    overspent,
    percentage,
    formattedValue,
    formattedRemaining,
    formattedOverspent,
    formattedTotalSpent,
    formattedPercentage,
    formattedDailyBudget,
  ];
}
