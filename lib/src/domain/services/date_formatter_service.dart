abstract interface class IDateFormatterService {
  int fromIsoDate(String iso);
  String toIsoDate(int millis);

  String formatTime(int millis);
  String formatMonth(DateTime date);
  String formatDayMonth(int millis);
  String formatShortDate(int millis);

  int daysUntil(int endMillis);
  String relativeGroupHeader(int millis);
  String formatPeriod(int startMillis, int endMillis);
}
