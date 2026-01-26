import 'package:intl/intl.dart';

abstract interface class IMoneyDto {
  double parse(String value);
  String format(double value);
  String formatWithoutSymbol(double value);
}

final class MoneyDto implements IMoneyDto {
  final NumberFormat _formatter;

  MoneyDto()
    : _formatter = NumberFormat.currency(
        symbol: 'R\$',
        locale: 'pt_BR',
        decimalDigits: 2,
      );

  @override
  String format(double value) => _formatter.format(value);

  @override
  String formatWithoutSymbol(double value) =>
      format(value).replaceAll('R\$', '').trim();

  @override
  double parse(String value) {
    final normalized = value
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(normalized) ?? 0.0;
  }
}
