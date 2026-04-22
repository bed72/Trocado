import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/expense/expense_category.dart';

void main() {
  group('ExpenseCategory.fromString', () {
    test('maps every known API string to matching enum value', () {
      expect(ExpenseCategory.fromString('food'), ExpenseCategory.food);
      expect(
        ExpenseCategory.fromString('transport'),
        ExpenseCategory.transport,
      );
      expect(ExpenseCategory.fromString('shopping'), ExpenseCategory.shopping);
      expect(ExpenseCategory.fromString('health'), ExpenseCategory.health);
      expect(ExpenseCategory.fromString('housing'), ExpenseCategory.housing);
      expect(ExpenseCategory.fromString('debt'), ExpenseCategory.debt);
      expect(
        ExpenseCategory.fromString('entertainment'),
        ExpenseCategory.entertainment,
      );
    });

    test('falls back to unknown for unmapped strings', () {
      expect(ExpenseCategory.fromString('travel'), ExpenseCategory.unknown);
      expect(ExpenseCategory.fromString(''), ExpenseCategory.unknown);
      expect(ExpenseCategory.fromString('FOOD'), ExpenseCategory.unknown);
    });

    test('falls back to unknown on null', () {
      expect(ExpenseCategory.fromString(null), ExpenseCategory.unknown);
    });
  });
}
