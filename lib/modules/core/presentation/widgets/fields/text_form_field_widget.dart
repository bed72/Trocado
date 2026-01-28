import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trocado/modules/core/presentation/animation/animation.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class TextFormFieldWidget extends StatefulWidget {
  final String hint;
  final bool? readOnly;
  final bool? absorbing;
  final bool obscureText;
  final FocusNode? focus;
  final String? placeholder;
  final String? initialValue;
  final Widget? helperWidget;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onPressedSuffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const TextFormFieldWidget({
    super.key,
    required this.hint,
    this.focus,
    this.readOnly,
    this.absorbing,
    this.onChanged,
    this.validator,
    this.controller,
    this.suffixIcon,
    this.placeholder,
    this.inputAction,
    this.initialValue,
    this.keyboardType,
    this.helperWidget,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onPressedSuffixIcon,
    this.obscureText = false,
  });

  @override
  State<TextFormFieldWidget> createState() => _TextFormFieldWidgetState();
}

class _TextFormFieldWidgetState extends State<TextFormFieldWidget> {
  late FocusNode _focus;
  late TextEditingController _controller;

  String? _failure;

  bool get _hasFailure => _failure != null;
  bool get _collapsed => _focus.hasFocus || _controller.text.isNotEmpty;

  bool get _showHelperWidget =>
      widget.helperWidget != null && !_hasFailure && widget.placeholder != null;
  bool get _showPlaceholder =>
      _collapsed &&
      _controller.text.isEmpty &&
      !_hasFailure &&
      widget.placeholder != null;
  Color get _color {
    if (_hasFailure) return context.colors.error;
    if (_focus.hasFocus) return context.colors.primary;

    return context.colors.onSurfaceVariant.withValues(alpha: 0.8);
  }

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

          _showHelperWidget ? widget.helperWidget! : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Text _buildPlaceholder() => Text(
    widget.placeholder!,
    style: context.typography.bodySmall?.copyWith(
      color: _color.withValues(alpha: .6),
    ),
  );

  Container _buildBorder() => Container(
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius300,
      border: Border.all(width: 1.0, color: _color),
    ),
  );

  SwitcherAnimation _buildFailure() => SwitcherAnimation(
    child: _failure == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const .only(left: 4.0, top: 4.0),
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
      top: _collapsed ? 14.0 : 23.0,
      child: AnimatedDefaultTextStyle(
        curve: Curves.easeOutCubic,
        duration: duration,
        style: context.typography.bodySmall!.copyWith(
          color: _color,
          fontSize: _collapsed ? 12.0 : 14.0,
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
    autovalidateMode: .disabled,
    obscureText: widget.obscureText,
    readOnly: widget.readOnly ?? false,
    inputFormatters: widget.inputFormatters,
    cursorRadius: const Radius.circular(2.0),
    onFieldSubmitted: widget.onFieldSubmitted,
    keyboardType: widget.keyboardType ?? .text,
    textInputAction: widget.inputAction ?? .next,
    validator: (value) {
      final data = widget.validator?.call(value);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_failure != data) setState(() => _failure = data);
      });

      return data;
    },
    decoration: InputDecoration(
      filled: false,
      border: .none,
      errorText: null,
      errorBorder: .none,
      enabledBorder: .none,
      focusedBorder: .none,
      disabledBorder: .none,
      focusedErrorBorder: .none,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      hint: _showPlaceholder ? _buildPlaceholder() : null,
      suffixIcon: widget.suffixIcon == null
          ? null
          : IconButton(
              onPressed: widget.onPressedSuffixIcon,
              icon: Icon(widget.suffixIcon, color: _color),
            ),
      contentPadding: .only(
        top: 30.0,
        left: 20.0,
        bottom: _hasFailure ? 14.0 : 18.0,
        right: 20.0 + (widget.suffixIcon != null ? 36 : 0),
      ),
    ),
  );

  void _forceLabelAnimation() {
    if (!mounted) return;
    setState(() {});
  }
}
