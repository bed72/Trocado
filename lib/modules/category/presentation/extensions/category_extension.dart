import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/data/category_data.dart';

extension CategoryStateExtension on CategoryData {
  bool supports(TransactionTypeData type) => types.contains(type);

  bool get isIncome => supports(.income);
  bool get isExpense => supports(.expense);
}
