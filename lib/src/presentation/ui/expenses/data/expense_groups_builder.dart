import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_group_presentation_data.dart';

List<ExpenseGroupPresentationData> buildExpenseGroups(
  List<ExpenseItemPresentationData> items, {
  required IDateFormatterService dateFormatter,
}) {
  if (items.isEmpty) return const [];

  final groups = <ExpenseGroupPresentationData>[];
  String? current;
  List<ExpenseItemPresentationData> currentBucket = [];

  for (final item in items) {
    final header = dateFormatter.relativeGroupHeader(item.expense.createdAt);

    if (current == null || current != header) {
      if (current != null) {
        groups.add(
          ExpenseGroupPresentationData(
            header: current,
            expenses: currentBucket,
          ),
        );
      }
      current = header;
      currentBucket = [item];
    } else {
      currentBucket.add(item);
    }
  }

  if (current != null) {
    groups.add(
      ExpenseGroupPresentationData(header: current, expenses: currentBucket),
    );
  }

  return groups;
}
