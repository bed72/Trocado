import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsCardWidget extends StatelessWidget {
  final List<Widget> children;

  const SettingsCardWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        borderRadius: .circular(16.0),
        color: context.colors.surfaceContainerLowest,
        border: .all(color: context.colors.outlineVariant),
      ),
      child: Column(children: _withDividers(context)),
    );
  }

  List<Widget> _withDividers(BuildContext context) {
    final List<Widget> widgets = [];
    for (int index = 0; index < children.length; index++) {
      widgets.add(
        Padding(
          padding: const .symmetric(horizontal: 16.0),
          child: children[index],
        ),
      );

      if (index < children.length - 1) {
        widgets.add(Divider(height: 1.0, color: context.colors.outlineVariant));
      }
    }

    return widgets;
  }
}
