import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/expense/expense_period_preset_enum.dart';

void main() {
  group('ExpensePeriodPresetEnum.toRange', () {
    test('currentMonth returns first and last day of now\'s month', () {
      final now = DateTime(2026, 4, 23, 14, 30);

      final range = ExpensePeriodPresetEnum.currentMonth.toRange(now: now);

      expect(range.startDate, DateTime(2026, 4, 1).millisecondsSinceEpoch);
      expect(
        range.endDate,
        DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('last30Days returns inclusive 30-day window ending today', () {
      final now = DateTime(2026, 4, 23, 14, 30);

      final range = ExpensePeriodPresetEnum.last30Days.toRange(now: now);

      expect(range.startDate, DateTime(2026, 3, 24).millisecondsSinceEpoch);
      expect(
        range.endDate,
        DateTime(2026, 4, 23, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('previousMonth returns the full previous month', () {
      final now = DateTime(2026, 4, 23);

      final range = ExpensePeriodPresetEnum.previousMonth.toRange(now: now);

      expect(range.startDate, DateTime(2026, 3, 1).millisecondsSinceEpoch);
      expect(
        range.endDate,
        DateTime(2026, 3, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('previousMonth wraps to the prior year when called in January', () {
      final now = DateTime(2026, 1, 15);

      final range = ExpensePeriodPresetEnum.previousMonth.toRange(now: now);

      expect(range.startDate, DateTime(2025, 12, 1).millisecondsSinceEpoch);
      expect(
        range.endDate,
        DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('custom throws UnsupportedError', () {
      expect(
        () => ExpensePeriodPresetEnum.custom.toRange(now: DateTime.now()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('labels are in pt_BR', () {
      expect(ExpensePeriodPresetEnum.currentMonth.label, 'Mês atual');
      expect(ExpensePeriodPresetEnum.last30Days.label, 'Últimos 30 dias');
      expect(ExpensePeriodPresetEnum.previousMonth.label, 'Mês passado');
      expect(ExpensePeriodPresetEnum.custom.label, 'Personalizado');
    });
  });
}
