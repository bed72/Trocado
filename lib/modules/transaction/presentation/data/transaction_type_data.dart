enum TransactionTypeData {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeData(this.label);

  static TransactionTypeData from(int value) => switch (value) {
    0 => .income,
    _ => .expense,
  };
}
