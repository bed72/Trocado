import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final bool? absorbing;
  final FocusNode? focus;
  final bool? obscureText;
  final Widget? helperWidget;
  final TextAlign? textAlign;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;

  const TextFieldWidget({
    super.key,
    required this.label,
    this.focus,
    this.onChanged,
    this.textAlign,
    this.absorbing,
    this.controller,
    this.obscureText,
    this.inputAction,
    this.onSubmitted,
    this.helperWidget,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: absorbing ?? false,
      child: TextField(
        maxLines: 1,
        cursorWidth: 2.0,
        focusNode: focus,
        autocorrect: false,
        onChanged: onChanged,
        controller: controller,
        onSubmitted: onSubmitted,
        textAlign: textAlign ?? .start,
        inputFormatters: inputFormatters,
        obscureText: obscureText ?? false,
        cursorRadius: const Radius.circular(2.0),
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: inputAction ?? TextInputAction.next,
        decoration: InputDecoration(
          isDense: true,
          hintText: label,
          errorMaxLines: 1,
          helperMaxLines: 1,
          helper: helperWidget,
          alignLabelWithHint: true,
          suffix: SizedBox(width: 16.0),
          prefix: SizedBox(width: 16.0),
        ),
      ),
    );
  }
}
