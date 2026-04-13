import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetDateFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const BudgetDateFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child: TextFieldWidget(
        label: 'Data de término',
        hint: 'Data de término',
        readOnly: true,
        absorbing: true,
        initialValue: DateTime.now().format(),
      ),
    );
  }
}
