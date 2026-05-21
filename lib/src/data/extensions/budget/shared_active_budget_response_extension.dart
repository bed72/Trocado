import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/budget/budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/budget_period_model.dart';
import 'package:trocado/src/domain/models/budget/partner_budget_slice_model.dart';
import 'package:trocado/src/domain/models/budget/shared_active_budget_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget/shared_active_budget_response.dart';

extension SharedActiveBudgetResponseExtension on SharedActiveBudgetResponse {
  SharedActiveBudgetModel toModel() => SharedActiveBudgetModel(
    me: me._toModel(),
    combined: combined._toModel(),
    period: period._toModel(),
    partner: partner._toModel(),
    partnerHasDifferentPeriod: partnerHasDifferentPeriod,
  );
}

extension on BudgetSliceResponse {
  BudgetSliceModel _toModel() => BudgetSliceModel(
    value: (double.parse(value) * 100).round(),
    remaining: (double.parse(remaining) * 100).round(),
    totalSpent: (double.parse(totalSpent) * 100).round(),
  );
}

extension on PartnerBudgetSliceResponse {
  PartnerBudgetSliceModel _toModel() => PartnerBudgetSliceModel(
    name: name,
    email: email,
    value: (double.parse(value) * 100).round(),
    remaining: (double.parse(remaining) * 100).round(),
    totalSpent: (double.parse(totalSpent) * 100).round(),
  );
}

extension on BudgetPeriodResponse {
  BudgetPeriodModel _toModel() => BudgetPeriodModel(
    endDate: DateFormat('yyyy-MM-dd').parse(endDate).millisecondsSinceEpoch,
    startDate: DateFormat('yyyy-MM-dd').parse(startDate).millisecondsSinceEpoch,
  );
}
