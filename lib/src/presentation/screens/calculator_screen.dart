import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/calculator/calculator_field_widget.dart';

import 'package:trocado/src/presentation/widgets/calculator/calculator_keyboard_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Continha Rápida',
      subtitle: 'Use a calculadora pra agilizar seus registros.',
      child: Padding(
        padding: const .only(top: 12, bottom: 20),
        child: Column(
          spacing: 16,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [CalculatorFieldWidget(), CalculatorKeyboard()],
        ),
      ),
    );
  }
}
