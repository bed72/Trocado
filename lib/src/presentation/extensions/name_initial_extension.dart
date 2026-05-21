import 'package:flutter/widgets.dart';

extension NameInitialExtension on String {
  String toInitial() {
    final trimmed = trim();
    return trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();
  }

  String toFirstName() => trim().split(' ').first;
}
