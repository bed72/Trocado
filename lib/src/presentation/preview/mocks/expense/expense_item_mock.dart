import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expense_category.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';

String formatPreviewValue(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

ExpenseItemData expenseItemMock({
  required int id,
  required Duration ago,
  required double value,
  required String description,
  required ExpenseCategory category,
}) {
  final moment = DateTime.now().subtract(ago);

  return ExpenseItemData(
    expense: ExpenseModel(
      id: id,
      category: category,
      description: description,
      value: (value * 100).round(),
      date: moment.millisecondsSinceEpoch,
      createdAt: moment.millisecondsSinceEpoch,
    ),
    formattedValue: formatPreviewValue(value),
  );
}
