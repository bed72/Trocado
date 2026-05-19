import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_value_preset_enum.dart';

void main() {
  group('ExpenseValuePresetEnum.toRange', () {
    test('upTo50 caps at 5000 cents with no lower bound', () {
      final range = ExpenseValuePresetEnum.upTo50.toRange();

      expect(range.maxValue, 5000);
      expect(range.minValue, isNull);
    });

    test('from50To200 spans 5000 to 20000 cents inclusive', () {
      final range = ExpenseValuePresetEnum.from50To200.toRange();

      expect(range.minValue, 5000);
      expect(range.maxValue, 20000);
    });

    test('from200To500 spans 20000 to 50000 cents inclusive', () {
      final range = ExpenseValuePresetEnum.from200To500.toRange();

      expect(range.minValue, 20000);
      expect(range.maxValue, 50000);
    });

    test('above500 starts at 50000 cents with no upper bound', () {
      final range = ExpenseValuePresetEnum.above500.toRange();

      expect(range.minValue, 50000);
      expect(range.maxValue, isNull);
    });
  });

  group('ExpenseValuePresetEnum.label', () {
    test('exposes a human-readable label per preset', () {
      expect(ExpenseValuePresetEnum.upTo50.label, 'Até R\$50');
      expect(ExpenseValuePresetEnum.above500.label, 'Acima de R\$500');
      expect(ExpenseValuePresetEnum.from50To200.label, 'R\$50 – R\$200');
      expect(ExpenseValuePresetEnum.from200To500.label, 'R\$200 – R\$500');
    });
  });
}
