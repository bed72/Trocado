import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

final class ExpenseItemPresentationData extends Equatable {
  final ExpenseModel expense;
  final String? authorName;
  final String formattedDate;
  final String formattedValue;

  const ExpenseItemPresentationData({
    required this.expense,
    required this.formattedDate,
    required this.formattedValue,
    this.authorName,
  });

  @override
  List<Object?> get props => [
    expense,
    formattedDate,
    formattedValue,
    authorName,
  ];
}
