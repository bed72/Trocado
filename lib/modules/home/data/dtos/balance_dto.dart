import 'package:trocado/modules/transaction/transaction.dart';

final class BalanceDto {
  final String label;
  final String amount;
  final TransactionTypeDto? type;

  const BalanceDto({required this.label, required this.amount, this.type});

  bool get isTotal => type == null;

  factory BalanceDto.empty({
    String label = '',
    String amount = '',
    TransactionTypeDto? type,
  }) => BalanceDto(label: label, amount: amount, type: type);

  factory BalanceDto.total({
    required double value,
    required String Function(double value) format,
  }) => BalanceDto(label: 'Total', amount: format(value));

  factory BalanceDto.income({
    required double value,
    required String Function(double value) format,
  }) => BalanceDto(type: .income, label: 'Receita', amount: format(value));

  factory BalanceDto.expense({
    required double value,
    required String Function(double value) format,
  }) => BalanceDto(type: .expense, label: 'Despesa', amount: format(value));
}
