import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String format() => DateFormat('dd/MM/yyyy', 'pt_BR').format(this);
}
