enum ExpenseOrderingEnum {
  dateAsc('date', 'Mais antigos'),
  valueAsc('value', 'Menor valor'),
  dateDesc('-date', 'Mais recentes'),
  valueDesc('-value', 'Maior valor');

  final String query;
  final String label;

  const ExpenseOrderingEnum(this.query, this.label);
}
