import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

void main() {
  group('ExpensePeriodPreset.toRange', () {
    test('currentMonth returns first and last day of now\'s month', () {
      final now = DateTime(2026, 4, 23, 14, 30);

      final range = ExpensePeriodPreset.currentMonth.toRange(now: now);

      expect(
        range.startDate,
        DateTime(2026, 4, 1).millisecondsSinceEpoch,
      );
      expect(
        range.endDate,
        DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('last30Days returns inclusive 30-day window ending today', () {
      final now = DateTime(2026, 4, 23, 14, 30);

      final range = ExpensePeriodPreset.last30Days.toRange(now: now);

      expect(
        range.startDate,
        DateTime(2026, 3, 24).millisecondsSinceEpoch,
      );
      expect(
        range.endDate,
        DateTime(2026, 4, 23, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('previousMonth returns the full previous month', () {
      final now = DateTime(2026, 4, 23);

      final range = ExpensePeriodPreset.previousMonth.toRange(now: now);

      expect(
        range.startDate,
        DateTime(2026, 3, 1).millisecondsSinceEpoch,
      );
      expect(
        range.endDate,
        DateTime(2026, 3, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('previousMonth wraps to the prior year when called in January', () {
      final now = DateTime(2026, 1, 15);

      final range = ExpensePeriodPreset.previousMonth.toRange(now: now);

      expect(
        range.startDate,
        DateTime(2025, 12, 1).millisecondsSinceEpoch,
      );
      expect(
        range.endDate,
        DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
      );
    });

    test('custom throws UnsupportedError', () {
      expect(
        () => ExpensePeriodPreset.custom.toRange(now: DateTime.now()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('labels are in pt_BR', () {
      expect(ExpensePeriodPreset.currentMonth.label, 'Mês atual');
      expect(ExpensePeriodPreset.last30Days.label, 'Últimos 30 dias');
      expect(ExpensePeriodPreset.previousMonth.label, 'Mês passado');
      expect(ExpensePeriodPreset.custom.label, 'Personalizado');
    });
  });
}
