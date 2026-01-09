import 'package:trocado/modules/core/core.dart';

final class BalanceState {
  final String label;
  final String amount;
  final TransactionTypeState? type;

  const BalanceState({required this.label, required this.amount, this.type});

  bool get isTotal => type == null;
}
