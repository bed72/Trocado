import 'package:rearch/rearch.dart';

(String, void Function(String)) descriptionCapsule(CapsuleHandle use) {
  final (value, setValue) = use.state<String>('');

  return (value, setValue);
}
