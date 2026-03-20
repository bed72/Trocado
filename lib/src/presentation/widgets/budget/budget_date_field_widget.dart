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
        readOnly: true,
        absorbing: true,
        hint: 'Data de término',
        initialValue: DateTime.now().format(),
      ),
    );
  }
}
