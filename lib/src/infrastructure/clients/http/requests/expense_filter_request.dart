import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

final class ExpenseFilterRequest {
  static const int defaultPageSize = 20;

  const ExpenseFilterRequest();

  String build({
    required ExpenseFilterModel? filter,
    String? cursor,
    int pageSize = defaultPageSize,
  }) {
    final fragments = <String>[];
    final hasActiveFilter = filter != null && !filter.isEmpty;

    if (hasActiveFilter) {
      if (filter.category != null) {
        fragments.add('eq(category,${filter.category!.name})');
      }
      if (filter.startDate != null) {
        fragments.add('ge(date,${_formatDate(filter.startDate!)})');
      }
      if (filter.endDate != null) {
        fragments.add('le(date,${_formatDate(filter.endDate!)})');
      }
      if (filter.minValue != null && filter.minValue! > 0) {
        fragments.add('ge(value,${_formatValue(filter.minValue!)})');
      }
      if (filter.maxValue != null && filter.maxValue! > 0) {
        fragments.add('le(value,${_formatValue(filter.maxValue!)})');
      }

      final trimmedDescription = filter.description.trim();
      if (trimmedDescription.isNotEmpty) {
        fragments.add(
          'like(description,${Uri.encodeComponent(trimmedDescription)}*)',
        );
      }

      fragments.add('ordering=${filter.ordering.query}');
      fragments.add('page_size=$pageSize');
    }

    if (cursor != null) fragments.add('cursor=$cursor');

    return fragments.join('&');
  }

  String _formatDate(int millis) => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));

  String _formatValue(int centavos) =>
      '${centavos ~/ 100}.${(centavos % 100).toString().padLeft(2, '0')}';
}
