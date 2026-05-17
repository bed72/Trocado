abstract interface class IDateFormatterService {
  int fromIsoDate(String iso);
  int daysUntil(int endMillis);
  String toIsoDate(int millis);

  String formatTime(int millis);
  String formatMonth(DateTime date);
  String formatDayMonth(int millis);
  String formatLongDate(int millis);
  String formatShortDate(int millis);
  String formatRelativePast(int millis);
  String formatInviteExpiration(int millis);

  String relativeGroupHeader(int millis);
  String formatPeriod(int startMillis, int endMillis);
}
