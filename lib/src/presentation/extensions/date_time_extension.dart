import 'package:intl/intl.dart';

final DateFormat _ptBrShortFormatter = DateFormat("d 'de' MMM", 'pt_BR');
final DateFormat _ptBrLongFormatter = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

extension StringToDateTimeExtension on String {
  DateTime toDateTime() => _ptBrLongFormatter.parse(this);
  int toMillisecondsSinceEpoch() => toDateTime().millisecondsSinceEpoch;
}

extension DateTimeExtensions on DateTime {
  String format() {
    final formatted = _ptBrLongFormatter.format(this);

    return formatted.replaceFirstMapped(
      RegExp(r'de (\w)'),
      (month) => 'de ${month[1]!.toUpperCase()}',
    );
  }

  String formatShort() {
    final formatted = _ptBrShortFormatter.format(this);

    return formatted.replaceFirstMapped(
      RegExp(r'de (\w)'),
      (match) => 'de ${match[1]!.toUpperCase()}',
    );
  }
}
