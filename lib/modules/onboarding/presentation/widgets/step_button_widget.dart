import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepButtonWidget extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final bool? enabled;
  final bool? loading;
  final VoidCallback? onTap;

  const StepButtonWidget({
    super.key,
    this.label,
    this.icon,
    this.onTap,
    this.enabled,
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
        enabled: enabled ?? true,
        loading: loading ?? false,
      ),
    );
  }
}
