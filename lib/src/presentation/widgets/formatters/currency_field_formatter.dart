import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

final class CurrencyFieldFormatter extends TextInputFormatter {
  final NumberFormat _formatter;

  CurrencyFieldFormatter({String locale = 'pt_BR'})
    : _formatter = NumberFormat.currency(
        symbol: '',
        locale: locale,
        decimalDigits: 2,
      );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final centavos = int.parse(digits);
    final formatted = _formatter.format(centavos / 100).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static int? parseCentavos(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.parse(digits);
  }

  static String formatCentavos(int? centavos, {String locale = 'pt_BR'}) {
    if (centavos == null || centavos == 0) return '';
    return NumberFormat.currency(
      symbol: '',
      locale: locale,
      decimalDigits: 2,
    ).format(centavos / 100).trim();
  }
}
