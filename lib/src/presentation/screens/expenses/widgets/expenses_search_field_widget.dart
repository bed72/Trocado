import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ExpensesSearchFieldWidget extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox(
    height: 36.0,
    child: TextField(
      cursorHeight: 16.0,
      onChanged: onChanged,
      controller: controller,
      textAlignVertical: .center,
      style: context.typography.bodyMedium?.copyWith(
        color: context.colors.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        isDense: true,
        hintText: 'Buscar por descrição',
        fillColor: context.colors.surfaceContainerHigh,
        hintStyle: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        contentPadding: const .symmetric(vertical: 0, horizontal: 12.0),
        prefixIcon: Icon(
          Icons.search,
          size: 18.0,
          color: context.colors.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36.0,
          minHeight: 36.0,
        ),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (_, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  padding: .zero,
                  iconSize: 18.0,
                  onPressed: onClear,
                  visualDensity: .compact,
                  constraints: const BoxConstraints(
                    minWidth: 36.0,
                    minHeight: 36.0,
                  ),
                  icon: Icon(
                    Icons.close,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 36.0,
          minHeight: 36.0,
        ),
        focusedBorder: _border(context.colors.primary),
        border: _border(context.colors.outline.withValues(alpha: 0.4)),
        enabledBorder: _border(context.colors.outline.withValues(alpha: 0.4)),
      ),
    ),
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: .circular(14.0),
    borderSide: BorderSide(color: color),
  );
}
