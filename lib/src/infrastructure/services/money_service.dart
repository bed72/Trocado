import 'package:intl/intl.dart';

import 'package:trocado/src/domain/services/interface_money_service.dart';

final class MoneyService implements IMoneyService {
  final NumberFormat _formatter;

  MoneyService()
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
