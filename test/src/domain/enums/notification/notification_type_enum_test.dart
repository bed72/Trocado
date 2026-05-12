import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';

void main() {
  group('NotificationTypeEnum.fromString', () {
    test('maps shared_expense_created', () {
      expect(
        NotificationTypeEnum.fromString('shared_expense_created'),
        NotificationTypeEnum.sharedExpenseCreated,
      );
    });

    test('maps budget_eighty_percent', () {
      expect(
        NotificationTypeEnum.fromString('budget_eighty_percent'),
        NotificationTypeEnum.budgetEightyPercent,
      );
    });

    test('falls back to unknown for any other value', () {
      expect(
        NotificationTypeEnum.fromString('random_new_type'),
        NotificationTypeEnum.unknown,
      );
      expect(NotificationTypeEnum.fromString(''), NotificationTypeEnum.unknown);
      expect(
        NotificationTypeEnum.fromString('SHARED_EXPENSE_CREATED'),
        NotificationTypeEnum.unknown,
      );
    });
  });
}
