DateTime dateTimeFromMilliseconds(int value) =>
    .fromMillisecondsSinceEpoch(value);

(int start, int end) currentMonthRange() {
  final now = DateTime.now();

  final start = DateTime(now.year, now.month);
  final end = DateTime(now.year, now.month + 1);

  return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}
