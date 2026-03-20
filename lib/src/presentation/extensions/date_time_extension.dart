import 'package:intl/intl.dart';

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
}
