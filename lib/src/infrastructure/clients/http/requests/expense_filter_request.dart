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

      if (filter.minValue != null) {
        fragments.add('ge(value,${_formatValue(filter.minValue!)})');
      }
      if (filter.maxValue != null) {
        fragments.add('le(value,${_formatValue(filter.maxValue!)})');
      }

      final trimmedDescription = filter.description.trim();
      if (trimmedDescription.isNotEmpty) {
        fragments.add(
          'ilike(description,*${Uri.encodeComponent(trimmedDescription)}*)',
        );
      }

      fragments.add('page_size=$pageSize');
    }

    if (cursor != null) fragments.add('cursor=$cursor');

    return fragments.join('&');
  }

  String _formatDate(int millis) =>
      DateFormat('yyyy-MM-dd').format(.fromMillisecondsSinceEpoch(millis));

  String _formatValue(int cents) => (cents / 100).toStringAsFixed(2);
}
