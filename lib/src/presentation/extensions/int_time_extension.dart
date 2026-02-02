import 'package:intl/intl.dart';

extension IntExtensions on int {
  String format() {
    final date = DateTime.fromMillisecondsSinceEpoch(this);

    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }
}
