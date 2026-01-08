import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepButtonWidget extends StatelessWidget {
  final String? label;
  final Widget? child;
  final bool? isLoading;
  final VoidCallback? onTap;

  const StepButtonWidget({
    super.key,
    this.label,
    this.child,
    this.onTap,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget.elevated(
        onTap: onTap,
        label: label,
        isLoading: isLoading,
        child: child,
      ),
    );
  }
}
