abstract interface class IMoneyService {
  double parse(String value);
  String format(double value);
  String formatWithoutSymbol(double value);
}
