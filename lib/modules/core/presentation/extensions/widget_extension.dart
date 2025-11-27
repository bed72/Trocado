import 'package:flutter/material.dart';

extension StateKeyboardExtension on State {
  void get hideKeyboard => FocusManager.instance.primaryFocus?.unfocus();
}

extension KeyboardExtensions on StatelessWidget {
  void get hideKeyboard => FocusManager.instance.primaryFocus?.unfocus();
}
