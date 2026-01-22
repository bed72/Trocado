enum TransactionTypeDto {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeDto(this.label);

  static TransactionTypeDto fromByInt(int value) => switch (value) {
    0 => .income,
    _ => .expense,
  };

  static TransactionTypeDto fromByString(String value) => .values.firstWhere(
    (transaction) => transaction.label == value,
    orElse: () => .expense,
  );
}
