enum TransactionTypeDto {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeDto(this.label);

  static TransactionTypeDto from(int value) => switch (value) {
    0 => .income,
    _ => .expense,
  };
}
