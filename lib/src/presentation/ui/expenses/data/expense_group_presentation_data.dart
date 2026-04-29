import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';

final class ExpenseGroupPresentationData extends Equatable {
  final String header;
  final List<ExpenseItemPresentationData> expenses;

  const ExpenseGroupPresentationData({required this.header, required this.expenses});

  @override
  List<Object?> get props => [header, expenses];
}
