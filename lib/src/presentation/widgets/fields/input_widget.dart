import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class InputWidget extends StatefulWidget {
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
  final VoidCallback? onTrailingIconTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final ValueChanged<bool>? onFocusChanged;

  const InputWidget({
    super.key,
    required this.hint,
    required this.label,
    this.failure,
    this.maxLines = 1,
    this.onChanged,
    this.controller,
    this.inputAction,
    this.initialValue,
    this.trailingIcon,
    this.keyboardType,
    this.onFocusChanged,
    this.enabled = true,
    this.readOnly = false,
    this.absorbing = false,
    this.onTrailingIconTap,
    this.obscureText = false,
  });

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  late final FocusNode _focus;
  late final TextEditingController? _controller;

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
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();

    _controller?.dispose();

    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focus.hasFocus);
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Column(
      spacing: 6.0,
      crossAxisAlignment: .start,
      children: [
        _buildLabel(color),
        AbsorbPointer(
          absorbing: widget.absorbing,
          child: _buildField(color),
        ),
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
    enabled: widget.enabled,
    readOnly: widget.readOnly,
    onChanged: widget.onChanged,
    obscureText: widget.obscureText,
    keyboardType: widget.keyboardType,
    textInputAction: widget.inputAction,
    textAlignVertical: .center,
    controller: widget.controller ?? _controller,
    maxLines: widget.obscureText ? 1 : widget.maxLines,
    style: context.typography.bodyMedium?.copyWith(color: color),
    decoration: InputDecoration(
      hintText: widget.hint,
      filled: _isFailure || _isFocused,
      constraints: const .tightFor(height: 64.0),
      errorBorder: _outlinedBorder(context.colors.error),
      focusedBorder: _outlinedBorder(context.colors.primary),
      border: _outlinedBorder(context.colors.onSurfaceVariant),
      focusedErrorBorder: _outlinedBorder(context.colors.error),
      contentPadding: const .symmetric(horizontal: 8.0, vertical: 20.0),
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
      suffixIcon: widget.trailingIcon == null
          ? null
          : IconButton(
              onPressed: widget.onTrailingIconTap,
              icon: Icon(widget.trailingIcon, color: color),
            ),
    ),
  );

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
