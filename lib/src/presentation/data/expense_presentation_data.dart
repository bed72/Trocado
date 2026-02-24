import 'package:trocado/src/presentation/data/category_presentation_data.dart';

sealed class ExpenseSavedPresentationData {
  const ExpenseSavedPresentationData();
}

final class ExpenseSavedSuccessPresentationData
    extends ExpenseSavedPresentationData {
  final String message;
  const ExpenseSavedSuccessPresentationData(this.message);
}

final class ExpenseSavedFailurePresentationData
    extends ExpenseSavedPresentationData {
  final String message;
  const ExpenseSavedFailurePresentationData(this.message);
}

final class ExpensePresentationData {
  final double amount;
  final DateTime date;
  final String description;
  final CategoryPresentationData category;

  const ExpensePresentationData({
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
  });

  bool get hasValidAmount => amount > 0;
  bool get hasValidDescription => description.trim().isNotEmpty;

  bool get isValid => hasValidDescription && hasValidAmount;

  ExpensePresentationData copyWith({
    double? amount,
    DateTime? date,
    String? description,
    CategoryPresentationData? category,
  }) => ExpensePresentationData(
    date: date ?? this.date,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    description: description ?? this.description,
  );

  @override
  String toString() =>
      'ExpensePresentationData('
      'description: "$description", '
      'amount: $amount, '
      'date: $date, '
      'category: $category, '
      'isValid: $isValid'
      ')';
}
