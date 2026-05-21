import 'package:equatable/equatable.dart';

final class MyBudgetSlicePresentationData extends Equatable {
  final double percentage;
  final String formattedValue;
  final String formattedSpent;
  final String formattedRemaining;

  const MyBudgetSlicePresentationData({
    required this.percentage,
    required this.formattedValue,
    required this.formattedSpent,
    required this.formattedRemaining,
  });

  @override
  List<Object?> get props => [
    percentage,
    formattedValue,
    formattedSpent,
    formattedRemaining,
  ];
}

final class PartnerBudgetSlicePresentationData extends Equatable {
  final String partnerName;
  final double percentage;
  final String formattedValue;
  final String formattedSpent;
  final String formattedRemaining;

  const PartnerBudgetSlicePresentationData({
    required this.partnerName,
    required this.percentage,
    required this.formattedValue,
    required this.formattedSpent,
    required this.formattedRemaining,
  });

  @override
  List<Object?> get props => [
    partnerName,
    percentage,
    formattedValue,
    formattedSpent,
    formattedRemaining,
  ];
}

final class SharedBudgetCardPresentationData extends Equatable {
  final bool overspent;
  final double percentage;
  final String formattedTotal;
  final String formattedSpent;
  final String formattedEndDate;
  final String formattedRemaining;
  final String formattedOverspent;
  final String formattedPercentage;
  final String formattedDailyBudget;
  final MyBudgetSlicePresentationData mySlice;
  final PartnerBudgetSlicePresentationData partnerSlice;
  final bool partnerHasDifferentPeriod;

  const SharedBudgetCardPresentationData({
    required this.overspent,
    required this.mySlice,
    required this.percentage,
    required this.partnerSlice,
    required this.formattedTotal,
    required this.formattedSpent,
    required this.formattedEndDate,
    required this.formattedRemaining,
    required this.formattedOverspent,
    required this.formattedPercentage,
    required this.formattedDailyBudget,
    required this.partnerHasDifferentPeriod,
  });

  @override
  List<Object?> get props => [
    overspent,
    mySlice,
    percentage,
    partnerSlice,
    formattedTotal,
    formattedSpent,
    formattedEndDate,
    formattedRemaining,
    formattedOverspent,
    formattedPercentage,
    formattedDailyBudget,
    partnerHasDifferentPeriod,
  ];
}
