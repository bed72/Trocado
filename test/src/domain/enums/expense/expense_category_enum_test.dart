import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

void main() {
  group('ExpenseCategoryEnum.fromString', () {
    test('maps every known API string to matching enum value', () {
      expect(ExpenseCategoryEnum.fromString('food'), ExpenseCategoryEnum.food);
      expect(
        ExpenseCategoryEnum.fromString('transport'),
        ExpenseCategoryEnum.transport,
      );
      expect(
        ExpenseCategoryEnum.fromString('shopping'),
        ExpenseCategoryEnum.shopping,
      );
      expect(
        ExpenseCategoryEnum.fromString('health'),
        ExpenseCategoryEnum.health,
      );
      expect(
        ExpenseCategoryEnum.fromString('housing'),
        ExpenseCategoryEnum.housing,
      );
      expect(ExpenseCategoryEnum.fromString('debt'), ExpenseCategoryEnum.debt);
      expect(
        ExpenseCategoryEnum.fromString('entertainment'),
        ExpenseCategoryEnum.entertainment,
      );
    });

    test('falls back to unknown for unmapped strings', () {
      expect(
        ExpenseCategoryEnum.fromString('travel'),
        ExpenseCategoryEnum.unknown,
      );
      expect(ExpenseCategoryEnum.fromString(''), ExpenseCategoryEnum.unknown);
      expect(
        ExpenseCategoryEnum.fromString('FOOD'),
        ExpenseCategoryEnum.unknown,
      );
    });

    test('falls back to unknown on null', () {
      expect(ExpenseCategoryEnum.fromString(null), ExpenseCategoryEnum.unknown);
    });
  });
}
