import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/date_time_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class BudgetDateFieldWidget extends StatelessWidget {
  final int? endDate;
  final int? startDate;
  final String? failure;
  final VoidCallback navigateTo;

  const BudgetDateFieldWidget({
    super.key,
    required this.navigateTo,
    this.endDate,
    this.failure,
    this.startDate,
  });

  String? get _displayValue {
    if (startDate == null || endDate == null) return null;
    final end = DateTime.fromMillisecondsSinceEpoch(endDate!).formatShort();
    final start = DateTime.fromMillisecondsSinceEpoch(startDate!).formatShort();

    return '$start até $end';
  }

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: navigateTo,
    child: TextFieldWidget(
      key: ValueKey(_displayValue),
      readOnly: true,
      absorbing: true,
      failure: failure,
      label: 'Período',
      initialValue: _displayValue,
      hint: 'Data de início e término',
    ),
  );
}
