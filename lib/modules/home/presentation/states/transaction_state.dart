import 'package:trocado/modules/core/core.dart';

final class TransactionState {
  final String label;
  final String amount;
  final CategoryState category;
  final TransactionTypeState type;

  const TransactionState({
    required this.type,
    required this.label,
    required this.amount,
    required this.category,
  });
}
