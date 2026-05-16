import 'package:intl/intl.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';

final class DateFormatterService implements IDateFormatterService {
  static const _locale = 'pt_BR';

  final DateTime Function() _now;

  final DateFormat _iso = DateFormat('yyyy-MM-dd');
  final DateFormat _time = DateFormat('HH:mm', _locale);
  final DateFormat _month = DateFormat('MMMM', _locale);
  final DateFormat _weekday = DateFormat('EEEE', _locale);
  final DateFormat _dayMonth = DateFormat('dd/MM', _locale);
  final DateFormat _monthYear = DateFormat('MMMM y', _locale);
  final DateFormat _shortDate = DateFormat('dd/MM/yyyy', _locale);
  final DateFormat _dayMonthAbbrev = DateFormat('dd MMM', _locale);
  final DateFormat _dayMonthShortYear = DateFormat('dd/MM/yy', _locale);
  final DateFormat _inviteExpiration = DateFormat("dd/MM 'às' HH:mm", _locale);

  DateFormatterService({required DateTime Function() now}) : _now = now;

  @override
  String formatShortDate(int millis) =>
      _shortDate.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatDayMonth(int millis) =>
      _dayMonth.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatTime(int millis) =>
      _time.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatInviteExpiration(int millis) =>
      _inviteExpiration.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatRelativePast(int millis) {
    final past = DateTime.fromMillisecondsSinceEpoch(millis);
    final days = _now().difference(past).inDays;

    if (days < 7) return 'alguns dias';

    if (days < 30) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1 semana' : '$weeks semanas';
    }

    if (days < 365) {
      final months = days ~/ 30;
      return months == 1 ? '1 mês' : '$months meses';
    }

    final years = days ~/ 365;
    return years == 1 ? '1 ano' : '$years anos';
  }

  @override
  String formatMonth(DateTime date) => _capitalize(_month.format(date));

  @override
  String formatPeriod(int startMillis, int endMillis) {
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);

    final currentYear = _now().year;
    final sameYear = start.year == currentYear && end.year == currentYear;
    final format = sameYear ? _dayMonth : _dayMonthShortYear;

    return '${format.format(start)} – ${format.format(end)}';
  }

  @override
  String relativeGroupHeader(int millis) {
    final day = _atStartOfDay(DateTime.fromMillisecondsSinceEpoch(millis));
    final reference = _atStartOfDay(_now());
    final diff = reference.difference(day).inDays;

    return switch (diff) {
      0 => 'Hoje',
      1 => 'Ontem',
      >= 2 && < 7 => _weekdayHeader(day),
      _ => _capitalize(_monthYear.format(day)),
    };
  }

  @override
  int daysUntil(int endMillis) {
    final now = _now();
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays + 1;
  }

  @override
  String toIsoDate(int millis) =>
      _iso.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  int fromIsoDate(String iso) => _iso.parse(iso).millisecondsSinceEpoch;

  DateTime _atStartOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _weekdayHeader(DateTime day) {
    final weekday = _capitalize(_weekday.format(day));
    final dayMonth = _dayMonthAbbrev.format(day).toLowerCase();

    return '$weekday, $dayMonth';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
