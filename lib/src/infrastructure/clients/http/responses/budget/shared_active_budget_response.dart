final class BudgetSliceResponse {
  final String value;
  final String remaining;
  final String totalSpent;

  const BudgetSliceResponse({
    required this.value,
    required this.remaining,
    required this.totalSpent,
  });

  factory BudgetSliceResponse.fromJson(Map<String, dynamic> json) =>
      BudgetSliceResponse(
        value: json['value'] as String,
        remaining: json['remaining'] as String,
        totalSpent: json['total_spent'] as String,
      );
}

final class PartnerBudgetSliceResponse {
  final String name;
  final String email;
  final String value;
  final String remaining;
  final String totalSpent;

  const PartnerBudgetSliceResponse({
    required this.name,
    required this.email,
    required this.value,
    required this.remaining,
    required this.totalSpent,
  });

  factory PartnerBudgetSliceResponse.fromJson(Map<String, dynamic> json) =>
      PartnerBudgetSliceResponse(
        name: json['name'] as String,
        email: json['email'] as String,
        value: json['value'] as String,
        remaining: json['remaining'] as String,
        totalSpent: json['total_spent'] as String,
      );
}

final class BudgetPeriodResponse {
  final String endDate;
  final String startDate;

  const BudgetPeriodResponse({required this.endDate, required this.startDate});

  factory BudgetPeriodResponse.fromJson(Map<String, dynamic> json) =>
      BudgetPeriodResponse(
        endDate: json['end_date'] as String,
        startDate: json['start_date'] as String,
      );
}

final class SharedActiveBudgetResponse {
  final BudgetSliceResponse me;
  final BudgetSliceResponse combined;
  final BudgetPeriodResponse period;
  final PartnerBudgetSliceResponse partner;
  final bool partnerHasDifferentPeriod;

  const SharedActiveBudgetResponse({
    required this.me,
    required this.period,
    required this.partner,
    required this.combined,
    required this.partnerHasDifferentPeriod,
  });

  factory SharedActiveBudgetResponse.fromJson(Map<String, dynamic> json) =>
      SharedActiveBudgetResponse(
        period: BudgetPeriodResponse.fromJson(
          json['period'] as Map<String, dynamic>,
        ),
        me: BudgetSliceResponse.fromJson(json['me'] as Map<String, dynamic>),
        partner: PartnerBudgetSliceResponse.fromJson(
          json['partner'] as Map<String, dynamic>,
        ),
        combined: BudgetSliceResponse.fromJson(
          json['combined'] as Map<String, dynamic>,
        ),
        partnerHasDifferentPeriod:
            json['partner_has_different_period'] as bool,
      );
}
