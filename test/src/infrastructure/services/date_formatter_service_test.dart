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

  group('formatLongDate', () {
    test('omits the year when it matches the current year', () {
      final data = formatter.formatLongDate(
        DateTime(2026, 5, 17).millisecondsSinceEpoch,
      );

      expect(data, '17 de Mai');
    });

    test('includes the year when it differs from the current year', () {
      final data = formatter.formatLongDate(
        DateTime(2025, 11, 8).millisecondsSinceEpoch,
      );

      expect(data, '08 de Nov de 2025');
    });

    test('includes the year for a future year as well', () {
      final data = formatter.formatLongDate(
        DateTime(2027, 1, 1).millisecondsSinceEpoch,
      );

      expect(data, '01 de Jan de 2027');
    });

    test('pads single-digit day with leading zero', () {
      final data = formatter.formatLongDate(
        DateTime(2026, 1, 3).millisecondsSinceEpoch,
      );

      expect(data, '03 de Jan');
    });

    test('capitalizes every month abbreviation without trailing dot', () {
      final months = [
        (1, 'Jan'),
        (2, 'Fev'),
        (3, 'Mar'),
        (4, 'Abr'),
        (5, 'Mai'),
        (6, 'Jun'),
        (7, 'Jul'),
        (8, 'Ago'),
        (9, 'Set'),
        (10, 'Out'),
        (11, 'Nov'),
        (12, 'Dez'),
      ];

      for (final (month, label) in months) {
        final data = formatter.formatLongDate(
          DateTime(2026, month, 1).millisecondsSinceEpoch,
        );

        expect(data, '01 de $label');
      }
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

  group('formatInviteExpiration', () {
    test('returns "dd de Mês às HH:mm" with full capitalized month', () {
      final data = formatter.formatInviteExpiration(
        DateTime(2026, 5, 18, 18, 23).millisecondsSinceEpoch,
      );

      expect(data, '18 de Maio às 18:23');
    });

    test('pads single-digit day with leading zero', () {
      final data = formatter.formatInviteExpiration(
        DateTime(2026, 1, 3, 9, 5).millisecondsSinceEpoch,
      );

      expect(data, '03 de Janeiro às 09:05');
    });
  });

  group('formatMonth', () {
    test('returns capitalized full month name in pt_BR', () {
      final data = formatter.formatMonth(DateTime(2026, 3, 15));

      expect(data, 'Março');
    });
  });

  group('formatPeriod', () {
    test('collapses to single long date when both ends are the same day', () {
      final millis = DateTime(2026, 5, 20).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(millis, millis);

      expect(data, '20 de Mai');
    });

    test('collapses single day with year when outside current year', () {
      final millis = DateTime(2027, 5, 20).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(millis, millis);

      expect(data, '20 de Mai de 2027');
    });

    test('collapses to single day regardless of intra-day time differences', () {
      final start = DateTime(2026, 5, 20, 0, 0).millisecondsSinceEpoch;
      final end = DateTime(2026, 5, 20, 23, 59, 59).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '20 de Mai');
    });

    test('omits the year for ranges within the current year', () {
      final start = DateTime(2026, 5, 12).millisecondsSinceEpoch;
      final end = DateTime(2026, 5, 20).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '12 de Mai até 20 de Mai');
    });

    test('omits the year for current-year ranges across months', () {
      final start = DateTime(2026, 1, 5).millisecondsSinceEpoch;
      final end = DateTime(2026, 12, 31).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '05 de Jan até 31 de Dez');
    });

    test('shows the year only on the end when range crosses into next year', () {
      final start = DateTime(2026, 12, 20).millisecondsSinceEpoch;
      final end = DateTime(2027, 1, 25).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '20 de Dez até 25 de Jan de 2027');
    });

    test('handles a year-crossing range on the extreme boundary', () {
      final start = DateTime(2026, 12, 31).millisecondsSinceEpoch;
      final end = DateTime(2027, 1, 1).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data, '31 de Dez até 01 de Jan de 2027');
    });

    test('uses " até " separator and never the en-dash for distinct days', () {
      final start = DateTime(2026, 5, 12).millisecondsSinceEpoch;
      final end = DateTime(2026, 5, 20).millisecondsSinceEpoch;

      final data = formatter.formatPeriod(start, end);

      expect(data.contains(' até '), isTrue);
      expect(data.contains('–'), isFalse);
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

    test('returns weekday-feira + long dayMonth for weekday 2-6 days ago', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 10).millisecondsSinceEpoch,
      );

      expect(data, 'Domingo, 10 de Mai');
    });

    test('returns Sábado + long dayMonth without -feira suffix', () {
      final data = formatter.relativeGroupHeader(
        DateTime(2026, 5, 9).millisecondsSinceEpoch,
      );

      expect(data, 'Sábado, 09 de Mai');
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

  group('formatRelativePast', () {
    test('returns "alguns dias" when diff is under 7 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      );

      expect(data, 'alguns dias');
    });

    test('returns "1 semana" at exactly 7 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
      );

      expect(data, '1 semana');
    });

    test('returns "2 semanas" at 14 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 14)).millisecondsSinceEpoch,
      );

      expect(data, '2 semanas');
    });

    test('returns "1 mês" at exactly 30 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      );

      expect(data, '1 mês');
    });

    test('returns "4 meses" at 120 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
      );

      expect(data, '4 meses');
    });

    test('returns "1 ano" at exactly 365 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 365)).millisecondsSinceEpoch,
      );

      expect(data, '1 ano');
    });

    test('returns "2 anos" at 800 days', () {
      final data = formatter.formatRelativePast(
        fixedNow.subtract(const Duration(days: 800)).millisecondsSinceEpoch,
      );

      expect(data, '2 anos');
    });
  });
}
