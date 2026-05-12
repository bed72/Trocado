import 'package:intl/intl.dart';

final class BudgetRequest {
  final int value;
  final int startDate;
  final int endDate;
  final String description;

  const BudgetRequest({
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'value': (value / 100).toStringAsFixed(2),
    'start_date': DateFormat(
      'yyyy-MM-dd',
    ).format(.fromMillisecondsSinceEpoch(startDate)),
    'end_date': DateFormat(
      'yyyy-MM-dd',
    ).format(.fromMillisecondsSinceEpoch(endDate)),
    'description': description,
  };
}
