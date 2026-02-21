import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  static final DateFormat _ptBrLongFormatter = DateFormat(
    "d 'de' MMMM 'de' y",
    'pt_BR',
  );

  String format() {
    final formatted = _ptBrLongFormatter.format(this);

    return formatted.replaceFirstMapped(
      RegExp(r'de (\w)'),
      (month) => 'de ${month[1]!.toUpperCase()}',
    );
  }
}
