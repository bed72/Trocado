import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/calculator/presentation/widgets/calculator_keyboard_widget.dart';

class CalculatorScreen extends StatefulWidget {
  final CalculatorCubit cubit;

  const CalculatorScreen({super.key, required this.cubit});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final MoneyDto _moneyDto;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    widget.cubit.clear();
    _moneyDto = MoneyDto();
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
            BlocListener<CalculatorCubit, CalculatorState>(
              bloc: widget.cubit,
              listenWhen: (previous, current) =>
                  previous.amount != current.amount,
              listener: (_, state) {
                _controller.text = _moneyDto.format(state.amount);
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
