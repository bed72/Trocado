import 'package:trocado/src/domain/models/page_model.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';

import 'package:trocado/src/data/extensions/budget/budget_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/budget/budget_response.dart';

extension BudgetsResponseExtension on DataModel<List<BudgetResponse>> {
  PageModel<BudgetModel> toPageModel() => PageModel<BudgetModel>(
    items: data.map((item) => item.toModel()).toList(),
    nextCursor: _cursorFrom(link: links?['next'], metaKey: 'next_cursor'),
    previousCursor: _cursorFrom(
      metaKey: 'previous_cursor',
      link: links?['previous'] ?? links?['prev'],
    ),
  );

  String? _cursorFrom({Object? link, required String metaKey}) {
    final String? url = link as String?;
    final String? cursor = url == null
        ? null
        : Uri.parse(url).queryParameters['cursor'];
    if (cursor != null) return cursor;

    final pagination = meta?['pagination'];
    if (pagination is! Map) return null;

    return pagination[metaKey] as String?;
  }
}
