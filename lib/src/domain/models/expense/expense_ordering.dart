enum ExpenseOrdering {
  dateAsc('date', 'Mais antigos'),
  valueAsc('value', 'Menor valor'),
  dateDesc('-date', 'Mais recentes'),
  valueDesc('-value', 'Maior valor');

  final String query;
  final String label;

  const ExpenseOrdering(this.query, this.label);
}
