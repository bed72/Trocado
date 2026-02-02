import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

extension LocationKeyboardExtension on Location {
  void get hideKeyboard => FocusManager.instance.primaryFocus?.unfocus();
}

extension StateKeyboardExtension on State {
  void get hideKeyboard => FocusManager.instance.primaryFocus?.unfocus();
}

extension KeyboardExtensions on StatelessWidget {
  void get hideKeyboard => FocusManager.instance.primaryFocus?.unfocus();
}
