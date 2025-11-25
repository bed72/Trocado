import 'package:flutter/material.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class LoadWidget extends StatelessWidget {
  final Widget? child;

  const LoadWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.primary,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
