import 'package:equatable/equatable.dart';

final class BudgetPeriodModel extends Equatable {
  final int endDate;
  final int startDate;

  const BudgetPeriodModel({required this.endDate, required this.startDate});

  BudgetPeriodModel copyWith({int? endDate, int? startDate}) =>
      BudgetPeriodModel(
        endDate: endDate ?? this.endDate,
        startDate: startDate ?? this.startDate,
      );

  @override
  List<Object?> get props => [endDate, startDate];
}
