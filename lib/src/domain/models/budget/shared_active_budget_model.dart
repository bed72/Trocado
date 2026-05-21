import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/budget/budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/budget_period_model.dart';
import 'package:trocado/src/domain/models/budget/partner_budget_slice_model.dart';

final class SharedActiveBudgetModel extends Equatable {
  final BudgetSliceModel me;
  final BudgetSliceModel combined;
  final BudgetPeriodModel period;
  final PartnerBudgetSliceModel partner;
  final bool partnerHasDifferentPeriod;

  const SharedActiveBudgetModel({
    required this.me,
    required this.period,
    required this.partner,
    required this.combined,
    required this.partnerHasDifferentPeriod,
  });

  SharedActiveBudgetModel copyWith({
    BudgetSliceModel? me,
    BudgetSliceModel? combined,
    BudgetPeriodModel? period,
    PartnerBudgetSliceModel? partner,
    bool? partnerHasDifferentPeriod,
  }) => SharedActiveBudgetModel(
    me: me ?? this.me,
    period: period ?? this.period,
    partner: partner ?? this.partner,
    combined: combined ?? this.combined,
    partnerHasDifferentPeriod:
        partnerHasDifferentPeriod ?? this.partnerHasDifferentPeriod,
  );

  @override
  List<Object?> get props => [
    me,
    period,
    partner,
    combined,
    partnerHasDifferentPeriod,
  ];
}
