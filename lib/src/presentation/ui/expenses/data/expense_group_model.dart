import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/data/expense_item_data.dart';

final class ExpenseGroup extends Equatable {
  final String header;
  final List<ExpenseItemData> expenses;

  const ExpenseGroup({required this.header, required this.expenses});

  @override
  List<Object?> get props => [header, expenses];
}
