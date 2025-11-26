import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepTitleWidget extends StatelessWidget {
  final String value;

  const StepTitleWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: .center,
      style: context.typography.headlineMedium?.copyWith(
        height: 1.2,
        fontSize: 22.0,
        fontWeight: .w800,
      ),
    );
  }
}
