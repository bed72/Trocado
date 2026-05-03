import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';

extension BudgetResponseExtension on BudgetResponse {
  BudgetModel toModel() => BudgetModel(
    id: id,
    description: description,
    value: (double.parse(value) * 100).round(),
    endDate: DateFormat('yyyy-MM-dd').parse(endDate).millisecondsSinceEpoch,
    startDate: DateFormat('yyyy-MM-dd').parse(startDate).millisecondsSinceEpoch,
    totalSpent: totalSpent == null
        ? null
        : (double.parse(totalSpent!) * 100).round(),
    remaining: remaining == null
        ? null
        : (double.parse(remaining!) * 100).round(),
    createdAt: createdAt == null
        ? null
        : DateTime.parse(createdAt!).millisecondsSinceEpoch,
  );
}
