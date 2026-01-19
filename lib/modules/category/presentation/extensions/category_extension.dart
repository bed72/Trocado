import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';

extension CategoryStateExtension on CategoryDto {
  bool supports(TransactionTypeDto type) => types.contains(type);

  bool get isIncome => supports(.income);
  bool get isExpense => supports(.expense);
}
