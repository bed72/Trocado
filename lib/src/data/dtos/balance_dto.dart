import 'package:trocado/src/domain/models/transaction_model.dart';

final class BalanceDto {
  final String label;
  final double amount;
  final TransactionTypeModel? type;

  bool get isTotal => type == null;

  const BalanceDto({required this.label, required this.amount, this.type});

  factory BalanceDto.empty({
    String label = '',
    double amount = 0.0,
    TransactionTypeModel? type,
  }) => BalanceDto(label: label, amount: amount, type: type);

  factory BalanceDto.total({required double amount}) =>
      BalanceDto(label: 'Total', amount: amount);

  factory BalanceDto.income({required double amount}) =>
      BalanceDto(type: .income, label: 'Receita', amount: amount);

  factory BalanceDto.expense({required double amount}) =>
      BalanceDto(type: .expense, label: 'Despesa', amount: amount);
}
