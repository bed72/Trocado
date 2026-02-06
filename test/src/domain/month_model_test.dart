import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/notifiers/data/month_data.dart';

void main() {
  group('MonthModel', () {
    group('constructor', () {
      test('creates instance with correct values', () {
        const model = MonthData(year: 2026, month: 1);

        expect(model.year, 2026);
        expect(model.month, 1);
      });
    });

    group('factory now', () {
      test('creates instance with current month and year', () {
        final now = DateTime.now();
        final model = MonthData.now();

        expect(model.year, now.year);
        expect(model.month, now.month);
      });
    });

    group('next', () {
      test('returns next month in same year', () {
        const model = MonthData(year: 2026, month: 6);

        expect(model.next, const MonthData(year: 2026, month: 7));
      });

      test('returns January of next year when current month is December', () {
        const model = MonthData(year: 2026, month: 12);

        expect(model.next, const MonthData(year: 2027, month: 1));
      });
    });

    group('previous', () {
      test('returns previous month in same year', () {
        const model = MonthData(year: 2026, month: 6);

        expect(model.previous, const MonthData(year: 2026, month: 5));
      });

      test(
        'returns December of previous year when current month is January',
        () {
          const model = MonthData(year: 2026, month: 1);

          expect(model.previous, const MonthData(year: 2025, month: 12));
        },
      );
    });

    group('startAt', () {
      test('returns first millisecond of the month', () {
        const model = MonthData(year: 2026, month: 3);
        final expected = DateTime(2026, 3, 1).millisecondsSinceEpoch;

        expect(model.startAt, expected);
      });
    });

    group('endAt', () {
      test('returns last millisecond of the month', () {
        const model = MonthData(year: 2026, month: 3);
        final expected = DateTime(
          2026,
          4,
          0,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

        expect(model.endAt, expected);
      });

      test('handles February correctly', () {
        const model = MonthData(year: 2026, month: 2);
        final expected = DateTime(
          2026,
          3,
          0,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

        expect(model.endAt, expected);
      });

      test('handles leap year February correctly', () {
        const model = MonthData(year: 2024, month: 2);
        final expected = DateTime(
          2024,
          3,
          0,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

        expect(model.endAt, expected);
      });

      test('handles December correctly', () {
        const model = MonthData(year: 2026, month: 12);
        final expected = DateTime(
          2027,
          1,
          0,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;

        expect(model.endAt, expected);
      });
    });

    group('label', () {
      test('returns correct label for January', () {
        const model = MonthData(year: 2026, month: 1);

        expect(model.label, 'Janeiro 2026');
      });

      test('returns correct label for June', () {
        const model = MonthData(year: 2026, month: 6);

        expect(model.label, 'Junho 2026');
      });

      test('returns correct label for December', () {
        const model = MonthData(year: 2026, month: 12);

        expect(model.label, 'Dezembro 2026');
      });

      test('returns correct label for all months', () {
        const expectedLabels = [
          'Janeiro 2026',
          'Fevereiro 2026',
          'Março 2026',
          'Abril 2026',
          'Maio 2026',
          'Junho 2026',
          'Julho 2026',
          'Agosto 2026',
          'Setembro 2026',
          'Outubro 2026',
          'Novembro 2026',
          'Dezembro 2026',
        ];

        for (int i = 1; i <= 12; i++) {
          final model = MonthData(year: 2026, month: i);
          expect(model.label, expectedLabels[i - 1]);
        }
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        const model1 = MonthData(year: 2026, month: 6);
        const model2 = MonthData(year: 2026, month: 6);

        expect(model1, model2);
      });

      test('two instances with different month are not equal', () {
        const model1 = MonthData(year: 2026, month: 6);
        const model2 = MonthData(year: 2026, month: 7);

        expect(model1, isNot(model2));
      });

      test('two instances with different year are not equal', () {
        const model1 = MonthData(year: 2026, month: 6);
        const model2 = MonthData(year: 2027, month: 6);

        expect(model1, isNot(model2));
      });
    });

    group('props', () {
      test('contains month and year', () {
        const model = MonthData(year: 2026, month: 6);

        expect(model.props, [6, 2026]);
      });
    });
  });
}
