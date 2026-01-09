import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trocado/modules/core/presentation/animation/animation.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class TextFieldWidget extends StatefulWidget {
  final String hint;
  final bool? readOnly;
  final bool? absorbing;
  final bool obscureText;
  final FocusNode? focus;
  final Widget? suffixIcon;
  final String? initialValue;
  final Widget? helperWidget;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const TextFieldWidget({
    super.key,
    required this.hint,
    this.focus,
    this.readOnly,
    this.absorbing,
    this.onChanged,
    this.controller,
    this.suffixIcon,
    this.inputAction,
    this.onSubmitted,
    this.helperWidget,
    this.keyboardType,
    this.initialValue,
    this.inputFormatters,
    this.obscureText = false,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
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
    return AbsorbPointer(
      absorbing: widget.absorbing ?? false,
      child: Column(
        spacing: 2,
        crossAxisAlignment: .start,
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

          widget.helperWidget ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Container _buildBorder() => Container(
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      border: Border.all(
        width: 1.0,
        color: _hasFailure
            ? context.colors.error
            : _focus.hasFocus
            ? context.colors.primary
            : context.colors.primary,
      ),
    ),
  );

  SwitcherAnimation _buildFailure() => SwitcherAnimation(
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
        duration: duration,
        curve: Curves.easeOutCubic,
        style: context.typography.bodySmall!.copyWith(
          fontSize: _collapsed ? 12.0 : 14.0,
          height: _collapsed ? 1 : (20.0 / 14.0),
          letterSpacing: _collapsed ? 0.0 : -0.23,
          color: _hasFailure ? context.colors.error : context.colors.primary,
        ),
        child: Text(widget.hint),
      ),
    );
  }

  TextField _buildFormField() => TextField(
    maxLines: 1,
    cursorWidth: 2.0,
    cursorHeight: 16,
    focusNode: _focus,
    controller: _controller,
    onChanged: widget.onChanged,
    obscureText: widget.obscureText,
    onSubmitted: widget.onSubmitted,
    readOnly: widget.readOnly ?? false,
    inputFormatters: widget.inputFormatters,
    cursorRadius: const Radius.circular(2.0),
    keyboardType: widget.keyboardType ?? .text,
    textInputAction: widget.inputAction ?? .next,
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
        bottom: 18.0,
        right: 20.0 + (widget.suffixIcon != null ? 36 : 0),
      ),
    ),
  );

  void _forceLabelAnimation() => setState(() {});
}
