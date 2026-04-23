import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class TextFieldWidget extends StatefulWidget {
  final String hint;
  final int maxLines;
  final bool enabled;
  final String label;
  final bool readOnly;
  final bool absorbing;
  final String? failure;
  final bool obscureText;
  final String? initialValue;
  final IconData? trailingIcon;
  final TextInputType? keyboardType;
  final TextInputAction? inputAction;
  final bool hideTrailingIconWhenEmpty;
  final VoidCallback? onTrailingIconTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final ValueChanged<bool>? onFocusChanged;
  final List<TextInputFormatter>? inputFormatters;

  const TextFieldWidget({
    super.key,
    required this.hint,
    required this.label,
    this.failure,
    this.onChanged,
    this.controller,
    this.inputAction,
    this.initialValue,
    this.trailingIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.onFocusChanged,
    this.enabled = true,
    this.readOnly = false,
    this.absorbing = false,
    this.inputFormatters,
    this.onTrailingIconTap,
    this.obscureText = false,
    this.hideTrailingIconWhenEmpty = false,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late final FocusNode _focus;
  late final TextEditingController? _controller;

  bool _hasText = false;
  bool _isFocused = false;
  bool get _isFailure => widget.failure != null;

  Color _color(BuildContext context) {
    if (_isFocused) return context.colors.primary;
    if (_isFailure) return context.colors.error;
    return context.colors.onSurfaceVariant;
  }

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _controller = widget.controller == null && widget.initialValue != null
        ? TextEditingController(text: widget.initialValue)
        : null;

    _focus.addListener(_onFocusChange);

    final effectiveController = widget.controller ?? _controller;
    if (effectiveController != null) {
      _hasText = effectiveController.text.isNotEmpty;
      effectiveController.addListener(_onControllerChanged);
    } else if (widget.initialValue != null) {
      _hasText = widget.initialValue!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();

    (widget.controller ?? _controller)?.removeListener(_onControllerChanged);
    _controller?.dispose();

    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focus.hasFocus);
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  void _onControllerChanged() {
    final controller = widget.controller ?? _controller;
    if (controller != null) {
      setState(() => _hasText = controller.text.isNotEmpty);
    }
  }

  void _onChanged(String value) {
    if (widget.controller == null && _controller == null) {
      setState(() => _hasText = value.isNotEmpty);
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Column(
      spacing: 4.0,
      crossAxisAlignment: .start,
      children: [
        _buildLabel(color),
        AbsorbPointer(absorbing: widget.absorbing, child: _buildField(color)),
        if (_isFailure) _buildFailure(color),
      ],
    );
  }

  Widget _buildLabel(Color color) => Text(
    widget.label,
    style: context.typography.bodyLarge?.copyWith(
      color: color,
      fontWeight: .w500,
    ),
  );

  TextField _buildField(Color color) => TextField(
    focusNode: _focus,
    cursorHeight: 16.0,
    onChanged: _onChanged,
    enabled: widget.enabled,
    readOnly: widget.readOnly,
    textAlignVertical: .center,
    obscureText: widget.obscureText,
    keyboardType: widget.keyboardType,
    textInputAction: widget.inputAction,
    inputFormatters: widget.inputFormatters,
    controller: widget.controller ?? _controller,
    maxLines: widget.obscureText ? 1 : widget.maxLines,
    style: context.typography.bodyMedium?.copyWith(color: color),
    decoration: InputDecoration(
      hintText: widget.hint,
      filled: _isFailure || _isFocused,
      constraints: const .tightFor(height: 56.0),
      errorBorder: _outlinedBorder(context.colors.error),
      focusedBorder: _outlinedBorder(context.colors.primary),
      border: _outlinedBorder(context.colors.onSurfaceVariant),
      focusedErrorBorder: _outlinedBorder(context.colors.error),
      contentPadding: const .symmetric(horizontal: 12.0, vertical: 16.0),
      hintStyle: context.typography.bodyMedium?.copyWith(
        color: color.withValues(alpha: .6),
      ),
      fillColor: _isFocused
          ? context.colors.primary.withValues(alpha: .06)
          : context.colors.error.withValues(alpha: .06),
      disabledBorder: _outlinedBorder(
        context.colors.onSurfaceVariant.withValues(alpha: .4),
      ),
      enabledBorder: _outlinedBorder(
        _isFailure ? context.colors.error : context.colors.onSurfaceVariant,
      ),
      suffixIcon: _buildSuffixIcon(color),
    ),
  );

  Widget? _buildSuffixIcon(Color color) {
    if (widget.trailingIcon == null) return null;
    if (widget.hideTrailingIconWhenEmpty && !_hasText) return null;

    return IconButtonWidget(
      color: color,
      withoutBackground: true,
      icon: widget.trailingIcon!,
      onPress: () => widget.onTrailingIconTap?.call(),
    );
  }

  Widget _buildFailure(Color color) => Row(
    spacing: 6.0,
    children: [
      Icon(Icons.info_outline, color: color, size: 16.0),
      Expanded(
        child: Text(
          widget.failure!,
          style: context.typography.bodyMedium?.copyWith(color: color),
        ),
      ),
    ],
  );

  OutlineInputBorder _outlinedBorder(Color color) => OutlineInputBorder(
    borderRadius: .circular(16.0),
    borderSide: BorderSide(color: color),
  );
}
