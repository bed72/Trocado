import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';

final IDateFormatterService _formatter = DateFormatterService(
  now: DateTime.now,
);

String formatPreviewValue(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

ExpenseItemPresentationData expenseItemMock({
  required int id,
  required Duration ago,
  required double value,
  required String description,
  required ExpenseCategoryEnum category,
}) {
  final moment = DateTime.now().subtract(ago);
  final millis = moment.millisecondsSinceEpoch;

  return ExpenseItemPresentationData(
    expense: ExpenseModel(
      id: id,
      date: millis,
      createdAt: millis,
      category: category,
      description: description,
      value: (value * 100).round(),
    ),
    formattedValue: formatPreviewValue(value),
    formattedTime: _formatter.formatTime(millis),
    formattedDate: _formatter.formatDayMonth(millis),
  );
}
