import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/transaction/transaction.dart';

final class TransactionState {
  final String label;
  final String amount;
  final CategoryData category;
  final TransactionTypeData type;

  const TransactionState({
    required this.type,
    required this.label,
    required this.amount,
    required this.category,
  });
}
