abstract interface class IMoneyRepository {
  double parse(String value);
  String format(double value);
  String formatWithoutSymbol(double value);
}
