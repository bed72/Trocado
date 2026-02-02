import 'package:intl/intl.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';

final class MoneyRepository implements IMoneyRepository {
  final NumberFormat _formatter;

  MoneyRepository()
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
