import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';

void main() {
  late IDateFormatterService formatter;
  final fixedNow = DateTime(2026, 5, 12, 14, 30);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    formatter = DateFormatterService(now: () => fixedNow);
  });

  group('formatShortDate', () {
    test('returns dd/MM/yyyy in pt_BR', () {
      final data = formatter.formatShortDate(
        DateTime(2026, 3, 15).millisecondsSinceEpoch,
      );

      expect(data, '15/03/2026');
    });
  });

  group('formatDayMonth', () {
    test('returns dd/MM in pt_BR', () {
      final data = formatter.formatDayMonth(
        DateTime(2026, 3, 15).millisecondsSinceEpoch,
      );

      expect(data, '15/03');
    });
  });

  group('formatTime', () {
    test('returns HH:mm in pt_BR', () {
      final data = formatter.formatTime(
        DateTime(2026, 3, 15, 9, 5).millisecondsSinceEpoch,
      );

      expect(data, '09:05');
    });
  });

  group('formatMonth', () {
    test('returns capitalized full month name in pt_BR', () {
      final data = formatter.formatMonth(DateTime(2026, 3, 15));

      expect(data, 'Março');
    });
  });

  group('formatPeriod', () {
    test('uses dd/MM when both dates in current year', () {
      final start = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final end = DateTime(2026, 12, 31).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '01/01 – 31/12');
    });

    test('uses dd/MM/yy when crossing years', () {
      final start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
      final end = DateTime(2026, 1, 31).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '01/12/25 – 31/01/26');
    });

    test('uses dd/MM/yy when end is in a different year from now', () {
      final start = DateTime(2026, 11, 1).millisecondsSinceEpoch;
      final end = DateTime(2027, 1, 31).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '01/11/26 – 31/01/27');
    });
  });

  group('relativeGroupHeader', () {
    test('returns Hoje for today', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 12, 9, 0).millisecondsSinceEpoch,
      );

      expect(data, 'Hoje');
    });

    test('returns Ontem for yesterday', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 11).millisecondsSinceEpoch,
      );

      expect(data, 'Ontem');
    });

    test('returns weekday-feira + dayMonth for weekday 2-6 days ago', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 10).millisecondsSinceEpoch,
      );

      expect(data, 'Domingo, 10 mai.');
    });

    test('returns Sábado + dayMonth without -feira suffix', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 9).millisecondsSinceEpoch,
      );

      expect(data, 'Sábado, 09 mai.');
    });

    test('returns capitalized Month Year for 7+ days ago', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 3, 1).millisecondsSinceEpoch,
      );

      expect(data, 'Março 2026');
    });
  });

  group('daysUntil', () {
    test('returns inclusive number of days until end', () {
      final data = formatter.daysUntil(
        DateTime(2026, 5, 15, 6, 0).millisecondsSinceEpoch,
      );

      expect(data, 4);
    });

    test('returns 1 when end is today', () {
      final data = formatter.daysUntil(
        DateTime(2026, 5, 12, 23, 59).millisecondsSinceEpoch,
      );

      expect(data, 1);
    });

    test('returns 0 when end is yesterday', () {
      final data = formatter.daysUntil(
        DateTime(2026, 5, 11).millisecondsSinceEpoch,
      );

      expect(data, 0);
    });
  });

  group('toIsoDate and fromIsoDate', () {
    test('toIsoDate returns yyyy-MM-dd without locale', () {
      final data = formatter.toIsoDate(
        DateTime(2026, 3, 15).millisecondsSinceEpoch,
      );

      expect(data, '2026-03-15');
    });

    test('fromIsoDate parses yyyy-MM-dd to millis at start of day', () {
      final data = formatter.fromIsoDate('2026-03-15');

      expect(data, DateTime(2026, 3, 15).millisecondsSinceEpoch);
    });

    test('toIsoDate and fromIsoDate are symmetric at start of day', () {
      final original = DateTime(2026, 3, 15).millisecondsSinceEpoch;

      final iso = formatter.toIsoDate(original);

      expect(formatter.fromIsoDate(iso), original);
    });
  });
}
