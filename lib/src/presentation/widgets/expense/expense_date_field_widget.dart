import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/input_widget.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: const InputWidget(
        label: 'Data',
        hint: 'Data',
        readOnly: true,
        absorbing: true,
        // initialValue: date.format(),
      ),
    );
  }
}
