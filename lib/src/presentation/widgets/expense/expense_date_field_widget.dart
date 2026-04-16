import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';
import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpenseDateFieldWidget extends StatelessWidget {
  final int? date;
  final String? failure;
  final VoidCallback navigateTo;

  const ExpenseDateFieldWidget({
    super.key,
    required this.navigateTo,
    this.date,
    this.failure,
  });

  String? get _displayValue => date != null
      ? DateTime.fromMillisecondsSinceEpoch(date!).format()
      : null;

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: navigateTo,
    child: TextFieldWidget(
      key: ValueKey(_displayValue),
      readOnly: true,
      absorbing: true,
      failure: failure,
      label: 'Data',
      hint: 'Selecione a data',
      initialValue: _displayValue,
    ),
  );
}
