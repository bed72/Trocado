enum TransactionTypeState {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeState(this.label);
}
