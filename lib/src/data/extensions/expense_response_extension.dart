import 'package:intl/intl.dart';

import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/expense_response.dart';

extension ExpenseResponseExtension on ExpenseResponse {
  ExpenseModel toModel() => ExpenseModel(
    id: id,
    description: description,
    value: (double.parse(value) * 100).round(),
    date: DateFormat('yyyy-MM-dd').parse(date).millisecondsSinceEpoch,
  );
}
