import 'package:intl/intl.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';

final class DateFormatterService implements IDateFormatterService {
  static const _locale = 'pt_BR';

  final DateTime Function() _now;

  final DateFormat _iso = DateFormat('yyyy-MM-dd');
  final DateFormat _time = DateFormat('HH:mm', _locale);
  final DateFormat _month = DateFormat('MMMM', _locale);
  final DateFormat _weekday = DateFormat('EEEE', _locale);
  final DateFormat _monthAbbrev = DateFormat('MMM', _locale);
  final DateFormat _monthYear = DateFormat('MMMM y', _locale);

  DateFormatterService({required DateTime Function() now}) : _now = now;

  @override
  String formatLongDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = _capitalize(_monthAbbrev.format(date).replaceAll('.', ''));

    if (date.year == _now().year) return '$day de $month';

    return '$day de $month de ${date.year}';
  }

  @override
  String formatTime(int millis) =>
      _time.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatInviteExpiration(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = _capitalize(_month.format(date));

    return '$day de $month às ${_time.format(date)}';
  }

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
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final currentYear = _now().year;

    if (startDay == endDay) return _withOptionalYear(startDay, currentYear);

    final startLabel = _dayMonthLabel(startDay);
    final endLabel = _withOptionalYear(endDay, currentYear);

    return '$startLabel até $endLabel';
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

    return '$weekday, ${_dayMonthLabel(day)}';
  }

  String _dayMonthLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _capitalize(_monthAbbrev.format(date).replaceAll('.', ''));

    return '$day de $month';
  }

  String _withOptionalYear(DateTime date, int currentYear) {
    final base = _dayMonthLabel(date);

    if (date.year == currentYear) return base;

    return '$base de ${date.year}';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
