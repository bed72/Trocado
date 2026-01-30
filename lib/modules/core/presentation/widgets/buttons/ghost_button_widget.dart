import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class GhostButtonWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const GhostButtonWidget({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: context.radius.cornerRadius300,
        color: context.colors.surfaceBright.withValues(
          alpha: context.isDark ? .3 : .9,
        ),
      ),
      child: child,
    );
  }
}
