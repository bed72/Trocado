import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

extension LocationKeyboardExtension on Location {
  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}

extension StateKeyboardExtension on State {
  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}

extension KeyboardExtensions on StatelessWidget {
  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}
