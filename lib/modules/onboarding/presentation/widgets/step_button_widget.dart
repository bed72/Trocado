import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepButtonWidget extends StatelessWidget {
  final String? label;
  final Widget? child;
  final bool? loading;
  final VoidCallback? onTap;

  const StepButtonWidget({
    super.key,
    this.label,
    this.child,
    this.onTap,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget.elevated(
        onTap: onTap,
        label: label,
        loading: loading,
        child: child,
      ),
    );
  }
}
