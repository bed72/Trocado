import 'package:flutter/material.dart';

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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Continha Rápida',
      subtitle: 'Use a calculadora pra agilizar seus registros.',
      child: Padding(
        padding: const .only(top: 12.0, bottom: 20.0),
        child: Column(
          spacing: 16.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            BlocListener<TransactionCubit, TransactionState>(
              bloc: widget.cubit,
              listenWhen: (previous, current) =>
                  previous.form.amount != current.form.amount,
              listener: (_, state) {
                _controller.text = widget.cubit.format(state.form.amount);
              },
              child: TextFieldWidget(
                hint: 'Valor',
                readOnly: true,
                absorbing: true,
                placeholder: '100.0',
                controller: _controller,
              ),
            ),

            CalculatorKeyboard(
              onKeyTap: (key) {
                widget.cubit.onKeyTap(key);

                if (key == '✓') context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
