import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/domain/models/month_model.dart';

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
        IconButtonWidget(
          width: 36.0,
          height: 36.0,
          iconSize: 22.0,
          onPress: onPrevious,
          name: Icons.chevron_left,
          borderRadius: .circular(12.0),
        ),
        Text(
          month.label,
          style: context.typography.titleMedium?.copyWith(fontWeight: .w800),
        ),
        IconButtonWidget(
          width: 36.0,
          height: 36.0,
          iconSize: 22.0,
          onPress: onNext,
          name: Icons.chevron_right,
          borderRadius: .circular(12.0),
        ),
      ],
    );
  }
}
