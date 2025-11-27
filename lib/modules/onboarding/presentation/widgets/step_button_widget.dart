import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;

  const StepButtonWidget({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget.elevated(label: label, icon: icon, onTap: onTap),
    );
  }
}
