import 'package:intl/intl.dart';

final class ExpenseRequest {
  final int date;
  final int value;
  final String description;

  const ExpenseRequest({
    required this.date,
    required this.value,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'value': (value / 100).toStringAsFixed(2),
    'date': DateFormat('yyyy-MM-dd').format(.fromMillisecondsSinceEpoch(date)),
  };
}
