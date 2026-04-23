import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

import 'package:trocado/src/presentation/ui/calculator/notifiers/calculator_intent.dart';
import 'package:trocado/src/presentation/ui/calculator/notifiers/calculator_notifier.dart';
import 'package:trocado/src/presentation/ui/calculator/widgets/calculator_field_widget.dart';
import 'package:trocado/src/presentation/ui/calculator/widgets/calculator_keyboard_widget.dart';

class CalculatorScreen extends StatelessWidget {
  final void Function(int centValue) onValueConfirmed;

  const CalculatorScreen({super.key, required this.onValueConfirmed});

  void _onPopInvokedWithResult({required bool didPop, required WidgetRef ref}) {
    if (!didPop) return;

    final cent = ref.read(calculatorProvider).centValue;

    if (cent > 0) onValueConfirmed(cent);
  }

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final notifier = ref.read(calculatorProvider.notifier);
      final displayValue = ref.watch(
        calculatorProvider.select((s) => s.displayValue),
      );

      return PopScope(
        onPopInvokedWithResult: (didPop, _) =>
            _onPopInvokedWithResult(ref: ref, didPop: didPop),
        child: BottomSheetScaffoldWidget(
          title: 'Qual o valor?',
          subtitle: 'Informe o valor do orçamento.',
          child: Padding(
            padding: const .only(top: 12.0, bottom: 20.0),
            child: Column(
              spacing: 16.0,
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                CalculatorFieldWidget(displayValue: displayValue),
                CalculatorKeyboard(
                  onSubmit: context.pop,
                  onClear: () => notifier.dispatch(const ClearPressed()),
                  onDelete: () => notifier.dispatch(const DeletePressed()),
                  onDigit: (digit) => notifier.dispatch(DigitPressed(digit)),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
