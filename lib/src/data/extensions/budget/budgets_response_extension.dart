import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';

import 'package:trocado/src/data/extensions/budget/budget_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/budget/budgets_response.dart';

extension BudgetsResponseExtension on BudgetsResponse {
  BudgetsPageModel toPageModel() => BudgetsPageModel(
    nextCursor: _cursorFrom(next),
    previousCursor: _cursorFrom(previous),
    budgets: budgets.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(String? url) {
    if (url == null) return null;

    return Uri.parse(url).queryParameters['cursor'];
  }
}
