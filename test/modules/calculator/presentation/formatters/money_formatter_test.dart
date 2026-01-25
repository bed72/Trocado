import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/data/formatters/money_formater.dart';

void main() {
  late IMoneyFormatter formatter;

  setUp(() {
    formatter = MoneyFormatter();
  });

  test('format should format value to BRL', () {
    final data = formatter.format(1234.5);

    expect(_normalize(data), 'R\$ 1.234,50');
  });

  test('parse should convert BRL string to double', () {
    final data = formatter.parse('R\$ 1.234,50');

    expect(data, 1234.5);
  });

  test('formatWithoutSymbol should remove currency symbol', () {
    final data = formatter.formatWithoutSymbol(99.9);

    expect(data, '99,90');
  });

  test('parse invalid value returns 0.0', () {
    final data = formatter.parse('abc');

    expect(data, 0.0);
  });
}

String _normalize(String value) => value.replaceAll('\u00A0', ' ');
