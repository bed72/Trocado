enum ExpenseEvent { cleared, invalidExpense }

final class ExpenseModel {
  final String id;
  final double amount;
  final DateTime date;
  final String description;

  const ExpenseModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  @override
  String toString() => '$description - $amount';
}
