import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/states/category_state.dart';

extension CategoryStateExtension on CategoryState {
  bool supports(TransactionTypeState type) => types.contains(type);

  bool get isIncome => supports(.income);
  bool get isExpense => supports(.expense);
}
