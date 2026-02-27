import 'package:trocado/src/presentation/data/category_presentation_data.dart';

final class ExpensePresentationData {
  final int? id;
  final String date;
  final double amount;
  final String description;
  final String formattedAmount;
  final CategoryPresentationData category;

  const ExpensePresentationData({
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
    this.formattedAmount = '',
  });

  bool get hasValidAmount => amount > 0;
  bool get hasValidDescription => description.trim().isNotEmpty;
  bool get isValid => hasValidDescription && hasValidAmount;

  ExpensePresentationData copyWith({
    int? id,
    String? date,
    double? amount,
    String? description,
    String? formattedAmount,
    CategoryPresentationData? category,
  }) => ExpensePresentationData(
    id: id ?? this.id,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    description: description ?? this.description,
    formattedAmount: formattedAmount ?? this.formattedAmount,
  );
}
