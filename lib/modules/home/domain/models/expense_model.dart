enum ExpenseEvent { cleared, invalidExpense }

final class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;

  const ExpenseModel({
    required this.id,
    required this.date,
    required this.title,
    required this.amount,
  });

  @override
  String toString() => '$title - $amount';
}
