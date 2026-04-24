import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

final class ExpenseItemData extends Equatable {
  final ExpenseModel expense;
  final String formattedValue;

  const ExpenseItemData({
    required this.expense,
    required this.formattedValue,
  });

  @override
  List<Object?> get props => [expense, formattedValue];
}
