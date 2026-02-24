import 'package:rearch/rearch.dart';

(DateTime, void Function(DateTime)) dateCapsule(CapsuleHandle use) {
  final (value, setValue) = use.state<DateTime>(.now());

  return (value, setValue);
}
