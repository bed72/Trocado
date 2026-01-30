import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/date/date.dart';

void main() {
  group('dateTimeFromMilliseconds', () {
    test('should convert millisecondsSinceEpoch to DateTime correctly', () {
      final milliseconds = DateTime(2024, 1, 1, 12, 30).millisecondsSinceEpoch;

      final data = dateTimeFromMilliseconds(milliseconds);

      expect(data.day, 1);
      expect(data.hour, 12);
      expect(data.month, 1);
      expect(data.year, 2024);
      expect(data.minute, 30);
      expect(data.millisecondsSinceEpoch, milliseconds);
    });

    test('should handle zero milliseconds', () {
      final data = dateTimeFromMilliseconds(0);

      expect(data, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('currentMonthRange', () {
    test('should return start and end of current month in milliseconds', () {
      final now = DateTime.now();

      final (start, end) = currentMonthRange();

      final expectedStart = DateTime(
        now.year,
        now.month,
      ).millisecondsSinceEpoch;
      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
      ).millisecondsSinceEpoch;

      expect(start, expectedStart);
      expect(end, expectedEnd);
      expect(start < end, true);
    });

    test('start should be first day of month at midnight', () {
      final (start, _) = currentMonthRange();
      final date = DateTime.fromMillisecondsSinceEpoch(start);

      expect(date.day, 1);
      expect(date.hour, 0);
      expect(date.minute, 0);
      expect(date.second, 0);
    });
  });
}
