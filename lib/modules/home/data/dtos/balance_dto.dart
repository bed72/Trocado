import 'package:trocado/modules/transaction/transaction.dart';

final class BalanceDto {
  final String label;
  final String amount;
  final TransactionTypeDto? type;

  const BalanceDto({required this.label, required this.amount, this.type});

  bool get isTotal => type == null;
}
