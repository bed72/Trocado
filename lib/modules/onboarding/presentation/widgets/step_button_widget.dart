import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepButtonWidget extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final bool? loading;
  final VoidCallback? onTap;

  const StepButtonWidget({
    super.key,
    this.label,
    this.icon,
    this.onTap,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget.elevated(
        icon: icon,
        onTap: onTap,
        label: label,
        loading: loading ?? false,
      ),
    );
  }
}
