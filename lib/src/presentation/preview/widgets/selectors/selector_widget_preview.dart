import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/selectors/selector_widget.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

@TrocadoPreview(name: 'Padrão')
Widget previewSelector() => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const .all(16.0),
      child: SelectorWidget(
        selected: 0,
        onSelected: (_) {},
        options: const ['Todas', 'Despesas', 'Receitas'],
      ),
    ),
  ),
);
