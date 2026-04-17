import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/active_budget_response.dart';

extension ActiveBudgetResponseExtension on ActiveBudgetResponse {
  ActiveBudgetModel toModel() => ActiveBudgetModel(
    id: id,
    description: description,
    value: (double.parse(value) * 100).round(),
    startDate: DateFormat('yyyy-MM-dd').parse(startDate).millisecondsSinceEpoch,
    endDate: DateFormat('yyyy-MM-dd').parse(endDate).millisecondsSinceEpoch,
    totalSpent: (double.parse(totalSpent) * 100).round(),
    remaining: (double.parse(remaining) * 100).round(),
  );
}
