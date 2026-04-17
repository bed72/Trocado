import 'package:flutter/material.dart' hide ValueChanged;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/form/budget_form_intent.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/form/budget_form_notifier.dart';

import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_intent.dart';
import 'package:trocado/src/presentation/screens/calculator/notifiers/calculator_notifier.dart';

import 'package:trocado/src/presentation/screens/calculator/widgets/calculator_field_widget.dart';
import 'package:trocado/src/presentation/screens/calculator/widgets/calculator_keyboard_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CalculatorScreen extends StatelessWidget {
  final void Function(int centValue)? onValueConfirmed;

  const CalculatorScreen({super.key, this.onValueConfirmed});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final notifier = ref.read(calculatorProvider.notifier);
        final displayValue = ref.watch(
          calculatorProvider.select((s) => s.displayValue),
        );

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) return;
            final centValue = ref.read(calculatorProvider).centValue;
            if (centValue > 0) {
              if (onValueConfirmed != null) {
                onValueConfirmed!(centValue);
              } else {
                ref
                    .read(budgetFormProvider.notifier)
                    .dispatch(ValueChanged(centValue));
              }
            }
          },
          child: BottomSheetScaffoldWidget(
            title: 'Qual o valor?',
            subtitle: 'Informe o valor do orçamento.',
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
              child: Column(
                spacing: 16.0,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CalculatorFieldWidget(displayValue: displayValue),
                  CalculatorKeyboard(
                    onDigit: (d) => notifier.dispatch(DigitPressed(d)),
                    onDelete: () => notifier.dispatch(const DeletePressed()),
                    onClear: () => notifier.dispatch(const ClearPressed()),
                    onSubmit: context.pop,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
