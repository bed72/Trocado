import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/domain/models/month_model.dart';
import 'package:trocado/modules/home/presentation/widgets/month/month_button_widget.dart';

class MonthSelectorWidget extends StatelessWidget {
  final MonthModel month;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MonthSelectorWidget({
    super.key,
    required this.month,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        MonthButtonWidget(onPress: onPrevious, icon: Icons.chevron_left),
        Text(
          month.label,
          style: context.typography.titleMedium?.copyWith(fontWeight: .w800),
        ),
        MonthButtonWidget(onPress: onNext, icon: Icons.chevron_right),
      ],
    );
  }
}
