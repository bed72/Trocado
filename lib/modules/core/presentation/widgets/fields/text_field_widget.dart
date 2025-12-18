import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class TextFieldWidget extends StatelessWidget {
  final String hint;
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
    required this.hint,
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
        keyboardType: keyboardType ?? .text,
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
      ),
    );
  }
}

class CollapseTextFormField extends StatefulWidget {
  final String hint;
  final bool? absorbing;
  final bool obscureText;
  final FocusNode? focus;
  final Widget? suffixIcon;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const CollapseTextFormField({
    super.key,
    required this.hint,
    this.focus,
    this.absorbing,
    this.onChanged,
    this.validator,
    this.controller,
    this.suffixIcon,
    this.initialValue,
    this.keyboardType,
    this.inputAction,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  @override
  State<CollapseTextFormField> createState() => _CollapseTextFormFieldState();
}

class _CollapseTextFormFieldState extends State<CollapseTextFormField> {
  late FocusNode _focus;
  late TextEditingController _controller;

  String? _failure;

  bool get _hasFailure => _failure != null;
  bool get _collapsed => _focus.hasFocus || _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focus = widget.focus ?? FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    _focus.addListener(_forceLabelAnimation);
    _controller.addListener(_forceLabelAnimation);
  }

  @override
  void dispose() {
    if (widget.focus == null) _focus.dispose();
    if (widget.controller == null) _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64.0,
          child: Stack(
            children: [
              Positioned.fill(child: _buildBorder()),
              _buildLabel(),
              Positioned.fill(child: _buildFormField()),
            ],
          ),
        ),

        _buildFailure(),
      ],
    );
  }

  Container _buildBorder() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        width: 1.0,
        color: _hasFailure
            ? context.colors.error
            : _focus.hasFocus
            ? context.colors.onPrimary
            : context.colors.primary,
      ),
    ),
  );

  AnimatedSwitcher _buildFailure() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: _failure == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 4.0),
            child: Text(
              _failure!,
              style: context.typography.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
  );

  AnimatedPositioned _buildLabel() {
    final duration = const Duration(milliseconds: 300);

    return AnimatedPositioned(
      left: 20.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      top: _collapsed ? 14.0 : 22.0,
      child: AnimatedDefaultTextStyle(
        curve: Curves.easeOutCubic,
        duration: duration,
        style: context.typography.bodySmall!.copyWith(
          fontSize: _collapsed ? 12.0 : 14.0,
          letterSpacing: _collapsed ? 0.0 : -0.23,
          height: _collapsed ? (16.0 / 12.0) : (20.0 / 14.0),
          color: _hasFailure ? context.colors.error : context.colors.primary,
        ),
        child: Text(widget.hint),
      ),
    );
  }

  TextFormField _buildFormField() => TextFormField(
    maxLines: 1,
    cursorWidth: 2.0,
    cursorHeight: 16,
    focusNode: _focus,
    controller: _controller,
    onChanged: widget.onChanged,
    obscureText: widget.obscureText,
    autovalidateMode: .onUserInteraction,
    inputFormatters: widget.inputFormatters,
    cursorRadius: const Radius.circular(2.0),
    onFieldSubmitted: widget.onFieldSubmitted,
    keyboardType: widget.keyboardType ?? .text,
    textInputAction: widget.inputAction ?? .next,
    validator: (value) {
      final data = widget.validator?.call(value);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_failure != data) setState(() => _failure = data);
      });

      return data;
    },
    decoration: InputDecoration(
      filled: false,
      border: .none,
      errorBorder: .none,
      enabledBorder: .none,
      focusedBorder: .none,
      disabledBorder: .none,
      focusedErrorBorder: .none,
      suffixIcon: widget.suffixIcon,
      errorText: _hasFailure ? '' : null,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      contentPadding: .only(
        top: 30.0,
        left: 20.0,
        bottom: 14.0,
        right: 20.0 + (widget.suffixIcon != null ? 36 : 0),
      ),
    ),
  );

  void _forceLabelAnimation() => setState(() {});
}
