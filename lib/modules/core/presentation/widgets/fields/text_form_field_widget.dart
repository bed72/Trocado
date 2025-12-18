import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFormFieldWidget extends StatelessWidget {
  final String hint;
  final FocusNode? focus;
  final bool? obscureText;
  final Widget? helperWidget;
  final String? initialValue;
  final TextAlign? textAlign;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const TextFormFieldWidget({
    super.key,
    required this.hint,
    this.focus,
    this.onChanged,
    this.validator,
    this.textAlign,
    this.controller,
    this.obscureText,
    this.inputAction,
    this.helperWidget,
    this.initialValue,
    this.keyboardType,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 1,
      cursorWidth: 2.0,
      focusNode: focus,
      autocorrect: false,
      validator: validator,
      onChanged: onChanged,
      controller: controller,
      initialValue: initialValue,
      textAlign: textAlign ?? .start,
      inputFormatters: inputFormatters,
      obscureText: obscureText ?? false,
      onFieldSubmitted: onFieldSubmitted,
      keyboardType: keyboardType ?? .text,
      autovalidateMode: .onUserInteraction,
      textInputAction: inputAction ?? .next,
      cursorRadius: const Radius.circular(2.0),
      decoration: InputDecoration(
        hintText: hint,
        errorMaxLines: 1,
        helperMaxLines: 1,
        helper: helperWidget,
        suffix: SizedBox(width: 16.0),
        prefix: SizedBox(width: 16.0),
      ),
    );
  }
}
