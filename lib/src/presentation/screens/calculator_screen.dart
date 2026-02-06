import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';
import 'package:trocado/src/presentation/notifiers/transaction/transaction_notifier.dart';
import 'package:trocado/src/presentation/widgets/calculator/calculator_keyboard_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final notifier = ref.read(transactionProvider.notifier);
        final amount = ref.watch(
          transactionProvider.select((state) => state.form.amount),
        );

        final formatted = notifier.format(amount);
        if (controller.text != formatted) controller.text = formatted;

        return BottomSheetScaffoldWidget(
          title: 'Continha Rápida',
          subtitle: 'Use a calculadora pra agilizar seus registros.',
          child: Padding(
            padding: const .only(top: 12, bottom: 20),
            child: Column(
              spacing: 16,
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                TextFieldWidget(
                  hint: 'Valor',
                  readOnly: true,
                  absorbing: true,
                  placeholder: '100.0',
                  controller: controller,
                ),
                CalculatorKeyboard(
                  onKeyTap: (key) {
                    notifier.onKeyTap(key);
                    if (key == '✓') context.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
