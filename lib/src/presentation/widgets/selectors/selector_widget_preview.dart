import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:trocado/src/presentation/widgets/preview_widget.dart';
import 'package:trocado/src/presentation/widgets/selectors/selector_widget.dart';

@Preview(name: 'Selector')
Widget selectorPreview() {
  return PreviewWidget(
    child: SelectorWidget(
      selected: 0,
      onSelected: (_) {},
      options: const ['Todas', 'Despesas', 'Receitas'],
    ),
  );
}
