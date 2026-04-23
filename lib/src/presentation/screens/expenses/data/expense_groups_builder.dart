import 'package:intl/intl.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';
import 'package:trocado/src/presentation/screens/expenses/data/expense_group_model.dart';

List<ExpenseGroup> buildExpenseGroups(
  List<ExpenseItemData> items, {
  DateTime? now,
}) {
  if (items.isEmpty) return const [];

  final groups = <ExpenseGroup>[];
  final reference = _atStartOfDay(now ?? .now());
  String? current;
  List<ExpenseItemData> currentBucket = [];

  for (final item in items) {
    final day = _atStartOfDay(
      .fromMillisecondsSinceEpoch(item.expense.createdAt),
    );
    final header = _headerFor(day, reference);

    if (current == null || current != header) {
      if (current != null) {
        groups.add(ExpenseGroup(header: current, expenses: currentBucket));
      }
      current = header;
      currentBucket = [item];
    } else {
      currentBucket.add(item);
    }
  }

  if (current != null) {
    groups.add(ExpenseGroup(header: current, expenses: currentBucket));
  }

  return groups;
}

DateTime _atStartOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _headerFor(DateTime day, DateTime reference) {
  final diff = reference.difference(day).inDays;

  if (day == reference) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff >= 0 && diff < 7) return _weekdayHeader(day);

  return _monthHeader(day);
}

String _weekdayHeader(DateTime day) {
  final weekday = _capitalize(DateFormat('EEEE', 'pt_BR').format(day));
  final dayMonth = DateFormat('dd MMM', 'pt_BR').format(day).toLowerCase();

  return '$weekday, $dayMonth';
}

String _monthHeader(DateTime day) =>
    _capitalize(DateFormat('MMMM y', 'pt_BR').format(day));

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
