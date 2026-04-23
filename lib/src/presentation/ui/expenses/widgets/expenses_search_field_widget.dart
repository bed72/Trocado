import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class ExpensesSearchFieldWidget extends StatefulWidget {
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const ExpensesSearchFieldWidget({
    super.key,
    required this.onClear,
    required this.onChanged,
    required this.controller,
  });

  @override
  State<ExpensesSearchFieldWidget> createState() =>
      _ExpensesSearchFieldWidgetState();
}

class _ExpensesSearchFieldWidgetState extends State<ExpensesSearchFieldWidget> {
  bool _expanded = false;
  late final FocusNode _focus;

  static const _duration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _expanded = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _collapseAndClear() {
    final hadText = widget.controller.text.isNotEmpty;
    widget.controller.clear();
    _focus.unfocus();
    setState(() => _expanded = false);
    if (hadText) widget.onClear();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: .centerRight,
      child: AnimatedContainer(
        height: 36.0,
        duration: _duration,
        curve: Curves.easeOutCubic,
        width: _expanded ? constraints.maxWidth : 36.0,
        child: AnimatedSwitcher(
          duration: _duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _expanded ? _field(context) : _icon(context),
        ),
      ),
    ),
  );

  Widget _icon(BuildContext context) => IconButtonWidget(
    key: const ValueKey('collapsed'),
    width: 36.0,
    height: 36.0,
    iconSize: 18.0,
    onPress: _expand,
    icon: Icons.search,
  );

  Widget _field(BuildContext context) => TextField(
    key: const ValueKey('expanded'),
    focusNode: _focus,
    cursorHeight: 16.0,
    textAlignVertical: .center,
    onChanged: widget.onChanged,
    controller: widget.controller,
    style: context.typography.bodyMedium?.copyWith(
      color: context.colors.primary,
    ),
    decoration: InputDecoration(
      filled: true,
      isDense: true,
      hintText: 'Buscar por descrição',
      fillColor: context.colors.primary.withValues(alpha: 0.2),
      hintStyle: context.typography.bodyMedium?.copyWith(
        fontWeight: .w600,
        color: context.colors.primary,
      ),
      focusedBorder: _border(context.colors.primary),
      border: _border(context.colors.outline.withValues(alpha: 0.4)),
      contentPadding: const .symmetric(vertical: 0, horizontal: 12.0),
      enabledBorder: _border(context.colors.outline.withValues(alpha: 0.4)),
      prefixIcon: Icon(Icons.search, size: 18.0, color: context.colors.primary),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 36.0,
        minHeight: 36.0,
      ),
      suffixIcon: IconButton(
        padding: .zero,
        iconSize: 18.0,
        visualDensity: .compact,
        onPressed: _collapseAndClear,
        constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
        icon: Icon(Icons.close, color: context.colors.primary),
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 36.0,
        minHeight: 36.0,
      ),
    ),
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: .circular(14.0),
    borderSide: BorderSide(color: color),
  );
}
