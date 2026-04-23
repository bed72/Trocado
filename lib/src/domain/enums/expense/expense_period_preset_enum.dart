typedef ExpensePeriodRange = ({int startDate, int endDate});

enum ExpensePeriodPresetEnum {
  custom('Personalizado'),
  currentMonth('Mês atual'),
  previousMonth('Mês passado'),
  last30Days('Últimos 30 dias');

  final String label;

  const ExpensePeriodPresetEnum(this.label);

  ExpensePeriodRange toRange({required DateTime now}) => switch (this) {
    ExpensePeriodPresetEnum.currentMonth => (
      startDate: DateTime(now.year, now.month, 1).millisecondsSinceEpoch,
      endDate: DateTime(
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch,
    ),
    ExpensePeriodPresetEnum.last30Days => (
      startDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      endDate: DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch,
    ),
    ExpensePeriodPresetEnum.previousMonth => (
      startDate: DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch,
      endDate: DateTime(
        now.year,
        now.month,
        0,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch,
    ),
    ExpensePeriodPresetEnum.custom => throw UnsupportedError(
      'custom preset has no implicit range — pick start/end manually',
    ),
  };
}
